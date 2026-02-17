import gleam/result
import lumen

pub fn upgrade(
  socket: lumen.Socket,
  host: String,
  verified: Bool,
) -> Result(lumen.Socket, lumen.PosixError) {
  ssl_upgrade_(socket, host, verified)
}

pub fn send(
  socket: lumen.Socket,
  payload: BitArray,
) -> Result(lumen.Socket, lumen.PosixError) {
  ssl_send_(socket, payload)
  |> result.replace(socket)
}

pub fn receive(
  socket: lumen.Socket,
  length: Int,
  within timeout: Int,
) -> Result(BitArray, lumen.PosixError) {
  ssl_receive_(socket, length, timeout)
}

pub fn receive_forever(
  socket: lumen.Socket,
  length: Int,
) -> Result(BitArray, lumen.PosixError) {
  ssl_receive_forever_(socket, length)
}

pub fn shutdown(socket: lumen.Socket) -> Result(Nil, lumen.PosixError) {
  ssl_shutdown_(socket)
}

pub fn close(socket: lumen.Socket) -> Result(Nil, lumen.PosixError) {
  ssl_close_(socket)
}

@external(erlang, "ssl_ffi", "connect")
fn ssl_upgrade_(
  socket: lumen.Socket,
  host: String,
  verified: Bool,
) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "ssl_ffi", "send")
fn ssl_send_(
  socket: lumen.Socket,
  payload: BitArray,
) -> Result(Nil, lumen.PosixError)

@external(erlang, "ssl_ffi", "recv")
fn ssl_receive_(
  socket: lumen.Socket,
  length: Int,
  timeout: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "ssl_ffi", "recv_forever")
fn ssl_receive_forever_(
  socket: lumen.Socket,
  length: Int,
) -> Result(BitArray, lumen.PosixError)

@external(erlang, "ssl_ffi", "shutdown")
fn ssl_shutdown_(socket: lumen.Socket) -> Result(Nil, lumen.PosixError)

@external(erlang, "ssl_ffi", "close")
fn ssl_close_(socket: lumen.Socket) -> Result(Nil, lumen.PosixError)
