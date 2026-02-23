import gleam/result
import lumen/net

pub type Tcp

pub type TcpError {
  Closed
  Timeout
  SystemLimit
  Posix(net.Posix)
}

pub type ConnectOptions {
  ConnectOptions(
    address: net.Address,
    port: net.Port,
    ip_version: net.IpVersion,
    timeout: net.Timeout,
  )
}

pub fn new(address: net.Address, port: net.Port) -> ConnectOptions {
  ConnectOptions(address:, port:, ip_version: net.Ipv4, timeout: net.infinity)
}

pub fn ip_version(
  opts: ConnectOptions,
  ip_version: net.IpVersion,
) -> ConnectOptions {
  ConnectOptions(..opts, ip_version:)
}

pub fn timeout(opts: ConnectOptions, timeout: net.Timeout) -> ConnectOptions {
  ConnectOptions(..opts, timeout:)
}

pub fn connect(opts: ConnectOptions) -> Result(Tcp, TcpError) {
  opts.address
  |> tcp_connect_(net.port_to_int(opts.port), opts.ip_version, opts.timeout)
}

pub fn send(socket: Tcp, payload: BitArray) -> Result(Nil, TcpError) {
  tcp_send_(socket, payload)
}

pub fn receive(
  socket: Tcp,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, TcpError) {
  tcp_receive_(socket, length, timeout)
}

pub fn shutdown(socket: Tcp) -> Result(Nil, TcpError) {
  tcp_shutdown_(socket)
}

pub type ListenOptions {
  ListenOptions(ip_address: net.IpAddress)
}

pub fn listen(port: net.Port, opts: ListenOptions) -> Result(Tcp, TcpError) {
  port
  |> net.port_to_int
  |> tcp_listen_(opts)
}

pub fn accept(socket: Tcp, timeout: net.Timeout) -> Result(Tcp, TcpError) {
  tcp_accept_(socket, timeout)
}

pub fn close(socket: Tcp) -> Nil {
  tcp_close_(socket)
}

pub fn port(socket: Tcp) -> Result(net.Port, Nil) {
  inet_port_(socket)
  |> result.try(net.port)
}

@external(erlang, "lumen_ffi", "tcp_connect")
fn tcp_connect_(
  address: net.Address,
  port: Int,
  ip_version: net.IpVersion,
  timeout: net.Timeout,
) -> Result(Tcp, TcpError)

@external(erlang, "lumen_ffi", "tcp_recv")
fn tcp_receive_(
  socket: Tcp,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, TcpError)

@external(erlang, "lumen_ffi", "tcp_send")
fn tcp_send_(socket: Tcp, packet: BitArray) -> Result(Nil, TcpError)

@external(erlang, "lumen_ffi", "tcp_shutdown")
fn tcp_shutdown_(socket: Tcp) -> Result(Nil, TcpError)

@external(erlang, "lumen_ffi", "tcp_listen")
fn tcp_listen_(port: Int, opts: ListenOptions) -> Result(Tcp, TcpError)

@external(erlang, "lumen_ffi", "tcp_accept")
fn tcp_accept_(listener: Tcp, timeout: net.Timeout) -> Result(Tcp, TcpError)

@external(erlang, "lumen_ffi", "tcp_close")
fn tcp_close_(socket: Tcp) -> Nil

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: Tcp) -> Result(Int, Nil)
