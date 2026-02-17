import gleeunit
import lumen
import lumen/inet
import lumen/tcp

const host = "127.0.0.1"

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn connect_test() {
  let assert Ok(tcp_port) =
    tcp.ListenOptions(port: 0, ip_address: inet.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(tcp_port)

  let assert Ok(_socket) = lumen.connect(host, port_num, inet.Ipv4)
}

pub fn port_test() {
  let assert Ok(tcp) =
    tcp.ListenOptions(port: 0, ip_address: inet.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(tcp)

  assert port_num > 0
}
