import gleam/erlang/charlist.{type Charlist}
import gleam/result
import lumen/net

pub type Udp

pub type UdpError {
  Closed
  Timeout
  SystemLimit
  Posix(net.Posix)
}

pub fn open(port: net.Port) -> Result(Udp, UdpError) {
  port
  |> net.port_to_int
  |> udp_open_
}

pub fn connect(
  socket: Udp,
  host: String,
  port: net.Port,
) -> Result(Nil, UdpError) {
  host
  |> charlist.from_string
  |> udp_connect_(socket, _, net.port_to_int(port))
}

pub fn send(socket: Udp, payload: BitArray) -> Result(Nil, UdpError) {
  udp_send_(socket, payload)
}

pub type ReceiveData {
  ReceiveData(ip_address: net.IpAddress, port: Int, payload: BitArray)
}

pub fn receive(
  socket: Udp,
  length: Int,
  timeout: net.Timeout,
) -> Result(ReceiveData, UdpError) {
  udp_receive_(socket, length, timeout)
  |> result.map(fn(recv_data) {
    let #(ip_address, port, payload) = recv_data

    ReceiveData(ip_address:, port:, payload:)
  })
}

pub fn close(socket: Udp) -> Nil {
  udp_close_(socket)
}

pub fn port(socket: Udp) -> Result(net.Port, Nil) {
  inet_port_(socket)
  |> result.try(net.port)
}

@external(erlang, "lumen_ffi", "udp_open")
fn udp_open_(port: Int) -> Result(Udp, UdpError)

@external(erlang, "lumen_ffi", "udp_connect")
fn udp_connect_(socket: Udp, host: Charlist, port: Int) -> Result(Nil, UdpError)

@external(erlang, "lumen_ffi", "udp_send")
fn udp_send_(socket: Udp, payload: BitArray) -> Result(Nil, UdpError)

@external(erlang, "lumen_ffi", "udp_receive")
fn udp_receive_(
  socket: Udp,
  length: Int,
  timeout: net.Timeout,
) -> Result(#(net.IpAddress, Int, BitArray), UdpError)

@external(erlang, "lumen_ffi", "udp_close")
fn udp_close_(socket: Udp) -> Nil

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: Udp) -> Result(Int, Nil)
