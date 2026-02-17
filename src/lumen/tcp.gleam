import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen/inet

pub type Tcp

pub fn connect(
  host: String,
  port: Int,
  ip_version: inet.IpVersion,
) -> Result(Tcp, inet.PosixError) {
  host
  |> charlist.from_string
  |> tcp_connect_(port, ip_version)
}

pub fn send(socket: Tcp, payload: BitArray) -> Result(Tcp, inet.PosixError) {
  tcp_send_(socket, payload)
  |> result.replace(socket)
}

pub fn receive(
  socket: Tcp,
  length: Int,
  within timeout: Int,
) -> Result(BitArray, inet.PosixError) {
  tcp_receive_(socket, length, timeout)
}

pub fn receive_forever(
  socket: Tcp,
  length: Int,
) -> Result(BitArray, inet.PosixError) {
  tcp_receive_forever_(socket, length)
}

pub fn shutdown(socket: Tcp) -> Result(Nil, inet.PosixError) {
  tcp_shutdown_(socket)
}

pub type ListenOptions {
  ListenOptions(port: Int, ip_address: inet.IpAddress)
}

pub fn listen(opts: ListenOptions) -> Result(Tcp, inet.PosixError) {
  tcp_listen_(opts)
}

pub fn accept(socket: Tcp, timeout: Int) -> Result(Tcp, inet.PosixError) {
  tcp_accept_(socket, timeout)
}

pub fn close(socket: Tcp) -> Result(Nil, Nil) {
  tcp_close_(socket)
}

pub fn port(socket: Tcp) -> Result(Int, Nil) {
  inet_port_(socket)
}

@external(erlang, "lumen_ffi", "tcp_connect")
fn tcp_connect_(
  host: Charlist,
  port: Int,
  ip_version: inet.IpVersion,
) -> Result(Tcp, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_recv")
fn tcp_receive_(
  socket: Tcp,
  length: Int,
  timeout: Int,
) -> Result(BitArray, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_recv_forever")
fn tcp_receive_forever_(
  socket: Tcp,
  length: Int,
) -> Result(BitArray, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_send")
fn tcp_send_(socket: Tcp, packet: BitArray) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_shutdown")
fn tcp_shutdown_(socket: Tcp) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_listen")
fn tcp_listen_(opts: ListenOptions) -> Result(Tcp, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_accept")
fn tcp_accept_(listener: Tcp, timeout: Int) -> Result(Tcp, inet.PosixError)

@external(erlang, "lumen_ffi", "tcp_close")
fn tcp_close_(socket: Tcp) -> Result(Nil, Nil)

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: Tcp) -> Result(Int, Nil)
