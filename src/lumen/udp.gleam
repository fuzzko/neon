import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen/inet

pub type Udp

pub fn open(port: Int) -> Result(Udp, inet.PosixError) {
  udp_open_(port)
}

pub fn connect(
  socket: Udp,
  host: String,
  port: Int,
) -> Result(Nil, inet.PosixError) {
  host
  |> charlist.from_string
  |> udp_connect_(socket, _, port)
}

pub fn send(socket: Udp, payload: BitArray) -> Result(Nil, inet.PosixError) {
  udp_send_(socket, payload)
}

pub type ReceiveData {
  ReceiveData(ip_address: inet.IpAddress, port: Int, payload: BitArray)
}

pub fn receive(
  socket: Udp,
  length: Int,
  within timeout: Int,
) -> Result(ReceiveData, inet.PosixError) {
  udp_receive_(socket, length, timeout)
  |> result.map(fn(recv_data) {
    let #(ip_address, port, payload) = recv_data

    ReceiveData(ip_address:, port:, payload:)
  })
}

pub fn receive_forever(
  socket: Udp,
  length: Int,
) -> Result(ReceiveData, inet.PosixError) {
  udp_receive_forever_(socket, length)
  |> result.map(fn(recv_data) {
    let #(ip_address, port, payload) = recv_data

    ReceiveData(ip_address:, port:, payload:)
  })
}

pub fn close(socket: Udp) -> Result(Nil, Nil) {
  udp_close_(socket)
}

pub fn port(socket: Udp) -> Result(Int, Nil) {
  inet_port_(socket)
}

@external(erlang, "lumen_ffi", "udp_open")
fn udp_open_(port: Int) -> Result(Udp, inet.PosixError)

@external(erlang, "lumen_ffi", "udp_connect")
fn udp_connect_(
  socket: Udp,
  host: Charlist,
  port: Int,
) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "udp_send")
fn udp_send_(socket: Udp, payload: BitArray) -> Result(Nil, inet.PosixError)

@external(erlang, "lumen_ffi", "udp_receive")
fn udp_receive_(
  socket: Udp,
  length: int,
  timeout: Int,
) -> Result(#(inet.IpAddress, Int, BitArray), inet.PosixError)

@external(erlang, "lumen_ffi", "udp_receive_forever")
fn udp_receive_forever_(
  socket: Udp,
  length: Int,
) -> Result(#(inet.IpAddress, Int, BitArray), inet.PosixError)

@external(erlang, "lumen_ffi", "udp_close")
fn udp_close_(socket: Udp) -> Result(Nil, Nil)

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: Udp) -> Result(Int, Nil)
