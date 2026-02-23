# neon

[![Package Version](https://img.shields.io/hexpm/v/neon)](https://hex.pm/packages/neon)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/neon/)

```sh
gleam add neon@1
```
```gleam
import gleam/io
import neon/net
import neon/tcp

pub fn main() {
  let assert Ok(port) = net.port(0)
  let assert Ok(listener) = tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))
  let assert Ok(port) = tcp.port(listener)

  let address = net.ip_address(net.Ipv4Address(127, 0, 0, 1))
  let assert Ok(socket) =
    tcp.new(address, port)
    |> tcp.connect

  let assert Ok(timeout) = net.timeout(5000)
  let assert Ok(server) = tcp.accept(listener, timeout)
  let assert Ok(Nil) = tcp.send(server, <<"hello world":utf8>>)

  let assert Ok(msg) = tcp.receive(socket, 11, timeout)
  let assert <<"hello world":utf8>> = msg
}
```

Further documentation can be found at <https://hexdocs.pm/neon>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
