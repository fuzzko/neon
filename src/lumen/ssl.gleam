import gleam/result
import lumen/inet
import lumen/tcp.{type Tcp}

pub type Ssl

pub fn upgrade(
  socket: Tcp,
  host: String,
  verified: Bool,
) -> Result(Ssl, inet.PosixError) {
  ssl_upgrade_(socket, host, verified)
}

pub fn send(socket: Ssl, payload: BitArray) -> Result(Ssl, inet.PosixError) {
  ssl_send_(socket, payload)
  |> result.replace(socket)
}

pub fn receive(
  socket: Ssl,
  length: Int,
  within timeout: Int,
) -> Result(BitArray, inet.PosixError) {
  ssl_receive_(socket, length, timeout)
}

pub fn receive_forever(
  socket: Ssl,
  length: Int,
) -> Result(BitArray, inet.PosixError) {
  ssl_receive_forever_(socket, length)
}

pub fn shutdown(socket: Ssl) -> Result(Nil, inet.PosixError) {
  ssl_shutdown_(socket)
}

pub fn close(socket: Ssl) -> Result(Nil, inet.PosixError) {
  ssl_close_(socket)
}

@external(erlang, "lumen_ffi", "ssl_connect")
fn ssl_upgrade_(
  socket: Tcp,
  host: String,
  verified: Bool,
) -> Result(Ssl, inet.PosixError)

@external(erlang, "lumen_ffi", "ssl_send")
fn ssl_send_(socket: Ssl, payload: BitArray) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "ssl_recv")
fn ssl_receive_(
  socket: Ssl,
  length: Int,
  timeout: Int,
) -> Result(BitArray, inet.PosixError)

@external(erlang, "lumen_ffi", "ssl_recv_forever")
fn ssl_receive_forever_(
  socket: Ssl,
  length: Int,
) -> Result(BitArray, inet.PosixError)

@external(erlang, "lumen_ffi", "ssl_shutdown")
fn ssl_shutdown_(socket: Ssl) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "ssl_close")
fn ssl_close_(socket: Ssl) -> Result(Nil, inet.PosixError)
