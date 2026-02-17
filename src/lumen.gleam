import gleam/result
import lumen/inet
import lumen/ssl.{type Ssl}
import lumen/tcp.{type Tcp}

pub opaque type Socket(a) {
  Socket(inner: a)
}

pub fn connect(
  host: String,
  port: Int,
  ip_version: inet.IpVersion,
) -> Result(Socket(Tcp), inet.PosixError) {
  host
  |> tcp.connect(port, ip_version)
  |> result.map(Socket)
}

pub fn upgrade(
  socket: Socket(Tcp),
  host: String,
  verified: Bool,
) -> Result(Socket(Ssl), inet.PosixError) {
  ssl.upgrade(socket.inner, host, verified)
  |> result.map(Socket)
}

pub fn send(
  socket: Socket(a),
  payload: BitArray,
  handle_send: fn(a, BitArray) -> Result(a, inet.PosixError),
) -> Result(Socket(a), inet.PosixError) {
  handle_send(socket.inner, payload)
  |> result.map(Socket)
}

pub fn receive(
  socket: Socket(a),
  length: Int,
  timeout: Int,
  handle_receive: fn(a, Int, Int) -> Result(BitArray, inet.PosixError),
) -> Result(BitArray, inet.PosixError) {
  handle_receive(socket.inner, length, timeout)
}

pub fn receive_forever(
  socket: Socket(a),
  length: Int,
  handle_receive_forever: fn(a, Int) -> Result(BitArray, inet.PosixError),
) -> Result(BitArray, inet.PosixError) {
  handle_receive_forever(socket.inner, length)
}

pub fn shutdown(
  socket: Socket(a),
  handle_shutdown: fn(a) -> Result(Nil, inet.PosixError),
) -> Result(Nil, inet.PosixError) {
  handle_shutdown(socket.inner)
}
