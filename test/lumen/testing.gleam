import gleam/erlang/process
import gleam/result
import lumen/net
import lumen/ssl.{type Ssl}
import lumen/tcp.{type Tcp}

const host = "127.0.0.1"

pub fn ssl_connected_pair() -> #(Ssl, Ssl) {
  let #(client_tcp, server_ssl) = tcp_connected_pair()
  let test_subject = process.new_subject()
  let #(cert, rsa_pk, ca_certs) = pkix_test_data()

  let _pid =
    process.spawn(fn() {
      let assert Ok(listener) = tcp.accept(server_ssl, net.Timeout(5000))
      let assert Ok(server_ssl) =
        ssl_handshake(listener, cert, rsa_pk, ca_certs, 5000)

      process.send(test_subject, server_ssl)

      process.receive_forever(process.new_subject())
    })

  let assert Ok(client_ssl) = ssl.upgrade(client_tcp, "127.0.0.1", False)
  let assert Ok(server_ssl) = process.receive(test_subject, 5000)

  #(client_ssl, server_ssl)
}

pub fn tcp_connected_pair() -> #(Tcp, Tcp) {
  start_ssl_server()

  let assert Ok(port) = net.port(0)

  let assert Ok(server_ssl) =
    tcp.ListenOptions(ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen(port, _)

  let assert Ok(port) = tcp.port(server_ssl)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(client_tcp) = tcp.connect(address, port, net.Ipv4)

  #(client_tcp, server_ssl)
}

@external(erlang, "ssl_test_ffi", "pkix_test_data")
pub fn pkix_test_data() -> #(BitArray, BitArray, List(BitArray))

@external(erlang, "ssl_test_ffi", "start_ssl_server")
pub fn start_ssl_server() -> Nil

@external(erlang, "ssl_test_ffi", "ssl_handshake")
pub fn ssl_handshake(
  listener: Tcp,
  cert: BitArray,
  rsa_private_key: BitArray,
  ca_certs: List(BitArray),
  timeout: Int,
) -> Result(Ssl, net.Posix)
