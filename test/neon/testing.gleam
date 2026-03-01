import gleam/erlang/process
import gleam/result
import neon/net
import neon/ssl.{type Ssl}
import neon/tcp.{type Tcp}

const host = "127.0.0.1"

pub fn ssl_connected_pair() -> #(Ssl, Ssl) {
  let #(cert, rsa_pk, ca_certs) = pkix_test_data()

  let assert Ok(loopback) = net.ipv4_address(127, 0, 0, 1)
  let assert Ok(port) = net.port(0)

  let assert Ok(listener) = ssl.listen(port, loopback)
  let assert Ok(listener_port) = ssl.port(listener)

  let hs_opts =
    ssl.handshake_options(cert, ssl.rsa_private_key(rsa_pk))
    |> ssl.cacerts(ca_certs)

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(transport) = ssl.accept(listener, timeout)
      let assert Ok(server_ssl) = ssl.handshake(transport, hs_opts)

      process.send(test_subject, server_ssl)
      process.receive_forever(process.new_subject())
    })

  let assert Ok(client_ssl) =
    ssl.new(host, listener_port)
    |> ssl.verify_none
    |> ssl.connect

  let assert Ok(server_ssl) = process.receive(test_subject, 5000)

  #(client_ssl, server_ssl)
}

pub fn tcp_connected_pair() -> #(Tcp, Tcp) {
  let assert Ok(port) = net.port(0)

  let assert Ok(loopback) = net.ipv4_address(127, 0, 0, 1)
  let assert Ok(server_tcp) = tcp.listen(port, loopback)

  let assert Ok(port) = tcp.port(server_tcp)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let opts = tcp.new(address, port)
  let assert Ok(client_tcp) = tcp.connect(opts)

  #(client_tcp, server_tcp)
}

@external(erlang, "ssl_test_ffi", "pkix_test_data")
pub fn pkix_test_data() -> #(BitArray, BitArray, List(BitArray))
