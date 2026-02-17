import lumen/inet
import lumen/tcp

pub fn port_test() {
  let assert Ok(tcp_port) = tcp.listen(0)
  let assert Ok(port_num) = inet.port(tcp_port)

  assert port_num > 0
}
