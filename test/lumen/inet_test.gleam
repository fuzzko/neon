import lumen
import lumen/inet
import lumen/tcp

pub fn port_test() {
  let assert Ok(tcp_port) =
    tcp.ListenOptions(port: 0, ip_address: lumen.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = inet.port(tcp_port)

  assert port_num > 0
}
