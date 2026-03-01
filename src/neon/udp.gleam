import gleam/option.{type Option, None, Some}
import gleam/result
import neon/net

pub type Udp

pub type UdpError {
  Closed
  Timeout
  SystemLimit
  Posix(net.Posix)
}

pub opaque type OpenOptions {
  OpenOptions(
    port: net.Port,
    ip_address: Option(net.IpAddress),
    ip_version: net.IpVersion,
  )
}

pub fn new(port: net.Port) -> OpenOptions {
  OpenOptions(port:, ip_address: None, ip_version: net.Ipv4)
}

pub fn ip_address(opts: OpenOptions, ip_address: net.IpAddress) -> OpenOptions {
  OpenOptions(..opts, ip_address: Some(ip_address))
}

pub fn ip_version(opts: OpenOptions, ip_version: net.IpVersion) -> OpenOptions {
  OpenOptions(..opts, ip_version:)
}

pub fn open(opts: OpenOptions) -> Result(Udp, UdpError) {
  udp_open_(net.port_to_int(opts.port), opts.ip_address, opts.ip_version)
}

pub fn connect(
  socket: Udp,
  address: net.Address,
  port: net.Port,
) -> Result(Nil, UdpError) {
  udp_connect_(socket, address, net.port_to_int(port))
}

pub fn send(socket: Udp, payload: BitArray) -> Result(Nil, UdpError) {
  udp_send_(socket, payload)
}

pub type ReceiveData {
  ReceiveData(ip_address: net.IpAddress, port: net.Port, payload: BitArray)
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

@external(erlang, "neon_ffi", "udp_open")
fn udp_open_(
  port: Int,
  ip_address: Option(net.IpAddress),
  ip_version: net.IpVersion,
) -> Result(Udp, UdpError)

@external(erlang, "neon_ffi", "udp_connect")
fn udp_connect_(
  socket: Udp,
  address: net.Address,
  port: Int,
) -> Result(Nil, UdpError)

@external(erlang, "neon_ffi", "udp_send")
fn udp_send_(socket: Udp, payload: BitArray) -> Result(Nil, UdpError)

@external(erlang, "neon_ffi", "udp_receive")
fn udp_receive_(
  socket: Udp,
  length: Int,
  timeout: net.Timeout,
) -> Result(#(net.IpAddress, net.Port, BitArray), UdpError)

@external(erlang, "neon_ffi", "udp_close")
fn udp_close_(socket: Udp) -> Nil

@external(erlang, "neon_ffi", "inet_port")
fn inet_port_(socket: Udp) -> Result(Int, Nil)
