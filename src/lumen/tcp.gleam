import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen

pub type Tcp

pub fn connect(
  host: String,
  port: Int,
  ip_version: lumen.IpVersion,
) -> Result(lumen.Socket(Tcp), lumen.PosixError) {
  host
  |> charlist.from_string
  |> tcp_connect_(port, ip_version)
}

pub fn send(
  socket: lumen.Socket(Tcp),
  payload: BitArray,
) -> Result(lumen.Socket(Tcp), lumen.PosixError) {
  tcp_send_(socket, payload)
  |> result.replace(socket)
}

pub fn receive(
  socket: lumen.Socket(Tcp),
  length: Int,
  within timeout: Int,
) -> Result(BitArray, lumen.PosixError) {
  tcp_receive_(socket, length, timeout)
}

pub fn receive_forever(
  socket: lumen.Socket(Tcp),
  length: Int,
) -> Result(BitArray, lumen.PosixError) {
  tcp_receive_forever_(socket, length)
}

pub fn shutdown(socket: lumen.Socket(Tcp)) -> Result(Nil, lumen.PosixError) {
  tcp_shutdown_(socket)
}

pub type ListenOptions {
  ListenOptions(port: Int, ip_address: lumen.IpAddress)
}

pub fn listen(
  opts: ListenOptions,
) -> Result(lumen.Socket(Tcp), lumen.PosixError) {
  tcp_listen_(opts)
}

pub fn accept(
  socket: lumen.Socket(Tcp),
  timeout: Int,
) -> Result(lumen.Socket(Tcp), lumen.PosixError) {
  tcp_accept_(socket, timeout)
}

pub fn close(socket: lumen.Socket(Tcp)) -> Result(Nil, Nil) {
  tcp_close_(socket)
}

@external(erlang, "lumen_ffi", "tcp_connect")
fn tcp_connect_(
  host: Charlist,
  port: Int,
  ip_version: lumen.IpVersion,
) -> Result(lumen.Socket(Tcp), lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_recv")
fn tcp_receive_(
  socket: lumen.Socket(Tcp),
  length: Int,
  timeout: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_recv_forever")
fn tcp_receive_forever_(
  socket: lumen.Socket(Tcp),
  length: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_send")
fn tcp_send_(
  socket: lumen.Socket(Tcp),
  packet: BitArray,
) -> Result(Nil, lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_shutdown")
fn tcp_shutdown_(socket: lumen.Socket(Tcp)) -> Result(Nil, lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_listen")
fn tcp_listen_(
  opts: ListenOptions,
) -> Result(lumen.Socket(Tcp), lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_accept")
fn tcp_accept_(
  listener: lumen.Socket(Tcp),
  timeout: Int,
) -> Result(lumen.Socket(Tcp), lumen.PosixError)

@external(erlang, "lumen_ffi", "tcp_close")
fn tcp_close_(socket: lumen.Socket(Tcp)) -> Result(Nil, Nil)
