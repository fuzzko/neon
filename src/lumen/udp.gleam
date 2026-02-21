import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen/net

pub type Udp

pub fn open(port: Int) -> Result(Udp, net.PosixError) {
  udp_open_(port)
}

pub fn connect(
  socket: Udp,
  host: String,
  port: Int,
) -> Result(Nil, net.PosixError) {
  host
  |> charlist.from_string
  |> udp_connect_(socket, _, port)
}

pub fn send(socket: Udp, payload: BitArray) -> Result(Nil, net.PosixError) {
  udp_send_(socket, payload)
}

pub type ReceiveData {
  ReceiveData(ip_address: net.IpAddress, port: Int, payload: BitArray)
}

pub fn receive(
  socket: Udp,
  length: Int,
  within timeout: Int,
) -> Result(ReceiveData, net.PosixError) {
  udp_receive_(socket, length, timeout)
  |> result.map(fn(recv_data) {
    let #(ip_address, port, payload) = recv_data

    ReceiveData(ip_address:, port:, payload:)
  })
}

pub fn receive_forever(
  socket: Udp,
  length: Int,
) -> Result(ReceiveData, net.PosixError) {
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
fn udp_open_(port: Int) -> Result(Udp, net.PosixError)

@external(erlang, "lumen_ffi", "udp_connect")
fn udp_connect_(
  socket: Udp,
  host: Charlist,
  port: Int,
) -> Result(Nil, net.PosixError)

@external(erlang, "lumen_ffi", "udp_send")
fn udp_send_(socket: Udp, payload: BitArray) -> Result(Nil, net.PosixError)

@external(erlang, "lumen_ffi", "udp_receive")
fn udp_receive_(
  socket: Udp,
  length: Int,
  timeout: Int,
) -> Result(#(net.IpAddress, Int, BitArray), net.PosixError)

@external(erlang, "lumen_ffi", "udp_receive_forever")
fn udp_receive_forever_(
  socket: Udp,
  length: Int,
) -> Result(#(net.IpAddress, Int, BitArray), net.PosixError)

@external(erlang, "lumen_ffi", "udp_close")
fn udp_close_(socket: Udp) -> Result(Nil, Nil)

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: Udp) -> Result(Int, Nil)
