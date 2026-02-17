import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen

pub fn connect(
  host: String,
  port: Int,
  ip_version: lumen.IpVersion,
) -> Result(lumen.Socket, lumen.PosixError) {
  host
  |> charlist.from_string
  |> tcp_connect_(port, ip_version)
}

pub fn send(
  socket: lumen.Socket,
  payload: BitArray,
) -> Result(lumen.Socket, lumen.PosixError) {
  tcp_send_(socket, payload)
  |> result.replace(socket)
}

pub fn receive(
  socket: lumen.Socket,
  length: Int,
  within timeout: Int,
) -> Result(BitArray, lumen.PosixError) {
  tcp_receive_(socket, length, timeout)
}

pub fn receive_forever(
  socket: lumen.Socket,
  length: Int,
) -> Result(BitArray, lumen.PosixError) {
  tcp_receive_forever_(socket, length)
}

pub fn shutdown(socket: lumen.Socket) -> Result(Nil, lumen.PosixError) {
  tcp_shutdown_(socket)
}

pub fn listen(port: Int) -> Result(lumen.Socket, lumen.PosixError) {
  tcp_listen_(port)
}

pub fn listen_ipv6(port: Int) -> Result(lumen.Socket, lumen.PosixError) {
  tcp_listen_ipv6_(port)
}

pub fn accept(
  socket: lumen.Socket,
  timeout: Int,
) -> Result(lumen.Socket, lumen.PosixError) {
  tcp_accept_(socket, timeout)
}

pub fn close(socket: lumen.Socket) -> Result(Nil, Nil) {
  tcp_close_(socket)
}

@external(erlang, "tcp_ffi", "connect")
fn tcp_connect_(
  host: Charlist,
  port: Int,
  ip_version: lumen.IpVersion,
) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "tcp_ffi", "recv")
fn tcp_receive_(
  socket: lumen.Socket,
  length: Int,
  timeout: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "tcp_ffi", "recv_forever")
fn tcp_receive_forever_(
  socket: lumen.Socket,
  length: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "tcp_ffi", "send")
fn tcp_send_(
  socket: lumen.Socket,
  packet: BitArray,
) -> Result(Nil, lumen.PosixError)

@external(erlang, "tcp_ffi", "shutdown")
fn tcp_shutdown_(socket: lumen.Socket) -> Result(Nil, lumen.PosixError)

@external(erlang, "tcp_ffi", "listen")
fn tcp_listen_(port: Int) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "tcp_ffi", "listen_ipv6")
fn tcp_listen_ipv6_(port: Int) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "tcp_ffi", "accept")
fn tcp_accept_(
  listener: lumen.Socket,
  timeout: Int,
) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "tcp_ffi", "close")
fn tcp_close_(socket: lumen.Socket) -> Result(Nil, Nil)
