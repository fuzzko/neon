import gleam/erlang/process
import gleeunit
import lumen
import lumen/net
import lumen/ssl.{type Ssl}
import lumen/tcp.{type Tcp}

const host = "127.0.0.1"

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn connect_test() {
  let assert Ok(tcp_port) =
    tcp.ListenOptions(port: 0, ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(tcp_port)

  let assert Ok(_socket) = lumen.connect(host, port_num, net.Ipv4)
}

pub fn port_test() {
  let assert Ok(tcp) =
    tcp.ListenOptions(port: 0, ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(tcp)

  assert port_num > 0
}

pub fn to_ssl_test() {
  start_ssl_server()
  let #(cert, rsa_pk, ca_certs) = pkix_test_data()

  // Create a TCP listener
  let assert Ok(listener) =
    tcp.ListenOptions(port: 0, ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen
  let assert Ok(port_num) = tcp.port(listener)

  let test_subject = process.new_subject()

  // Spawn a process to do the server-side SSL handshake
  let _pid =
    process.spawn(fn() {
      let assert Ok(accepted) = tcp.accept(listener, 5000)
      let assert Ok(_server_ssl) =
        ssl_handshake(accepted, cert, rsa_pk, ca_certs, 5000)
      process.send(test_subject, Nil)
    })

  // Connect through the lumen API and upgrade to SSL
  let assert Ok(socket) = lumen.connect(host, port_num, net.Ipv4)
  let assert Ok(_ssl_socket) = lumen.to_ssl(socket, host, False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- erlang FFI for test infrastructure ---------- //

@external(erlang, "ssl_test_ffi", "pkix_test_data")
fn pkix_test_data() -> #(BitArray, BitArray, List(BitArray))

@external(erlang, "ssl_test_ffi", "start_ssl_server")
fn start_ssl_server() -> Nil

@external(erlang, "ssl_test_ffi", "ssl_handshake")
fn ssl_handshake(
  listener: Tcp,
  cert: BitArray,
  rsa_private_key: BitArray,
  ca_certs: List(BitArray),
  timeout: Int,
) -> Result(Ssl, net.PosixError)
