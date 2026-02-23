import gleam/erlang/process
import gleam/result
import neon/net
import neon/tcp.{type Tcp}

// ---------- connect ---------- //

const host = "127.0.0.1"

pub fn port_test() {
  let assert Ok(port) = net.port(0)

  let assert Ok(tcp) = tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))

  let assert Ok(port) = tcp.port(tcp)

  assert net.port_to_int(port) > 0
}

pub fn connect_test() {
  let assert Ok(port) = net.port(0)

  let assert Ok(tcp_port) = tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))

  let assert Ok(port_num) = tcp.port(tcp_port)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(_socket) =
    address
    |> tcp.new(port_num)
    |> tcp.connect
}

pub fn connect_ipv6_test() {
  let assert Ok(port) = net.port(0)

  let assert Ok(tcp_port) =
    tcp.listen(port, net.Ipv6Address(0, 0, 0, 0, 0, 0, 0, 1))

  let assert Ok(port_num) = tcp.port(tcp_port)
  let assert Ok(address) =
    net.parse_ip_address("::1")
    |> result.map(net.ip_address)

  let assert Ok(_socket) =
    address
    |> tcp.new(port_num)
    |> tcp.ip_version(net.Ipv6)
    |> tcp.connect
}

pub fn connect_error_test() {
  let assert Ok(port) = net.port(1)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Error(tcp.Posix(net.Econnrefused)) =
    address
    |> tcp.new(port)
    |> tcp.ip_version(net.Ipv4)
    |> tcp.connect
}

// ---------- listen ---------- //

pub fn listen_error_test() {
  let assert Ok(port) = net.port(1)

  // Port 1 is privileged so listening should fail
  let assert Error(tcp.Posix(net.Eacces)) =
    tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))
}

// ---------- accept ---------- //

pub fn accept_timeout_test() {
  let assert Ok(port) = net.port(0)

  let assert Ok(listener) = tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))

  // No client connects, so accept should time out
  let assert Ok(timeout) = net.timeout(50)
  let assert Error(tcp.Timeout) = tcp.accept(listener, timeout)
}

// ---------- send ---------- //

pub fn send_test() {
  let #(socket, _listener) = connected_pair()

  let assert Ok(Nil) = tcp.send(socket, <<"hello":utf8>>)
  let assert Ok(Nil) = tcp.shutdown(socket)
}

pub fn send_closed_test() {
  let #(socket, _listener) = connected_pair()

  let assert Ok(_) = tcp.shutdown(socket)
  let assert Error(_posix) = tcp.send(socket, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  let #(socket, listener) = connected_pair()

  // Accept the connection on the server side and send data
  let assert Ok(timeout) = net.timeout(1000)
  let assert Ok(server_sock) = tcp.accept(listener, timeout)
  let assert Ok(_) = tcp.send(server_sock, <<"hello":utf8>>)

  let assert Ok(timeout) = net.timeout(1000)
  let assert Ok(<<"hello":utf8>>) = tcp.receive(socket, 5, timeout)

  let assert Ok(_) = tcp.shutdown(socket)
}

pub fn receive_timeout_test() {
  let #(socket, _listener) = connected_pair()

  // No data is sent, so receive should time out
  let assert Ok(timeout) = net.timeout(100)
  let assert Error(tcp.Timeout) = tcp.receive(socket, 1, timeout)

  let assert Ok(_) = tcp.shutdown(socket)
}

pub fn receive_closed_test() {
  let #(socket, listener) = connected_pair()

  let assert Ok(timeout) = net.timeout(1000)
  let assert Ok(server_sock) = tcp.accept(listener, timeout)
  tcp.close(server_sock)

  process.sleep(50)

  let assert Ok(timeout) = net.timeout(1000)
  let assert Error(tcp.Closed) = tcp.receive(socket, 1, timeout)
}

pub fn receive_forever_test() {
  let #(socket, listener) = connected_pair()
  let test_subject = process.new_subject()

  // Spawn a process that accepts and sends data, since receive with infinity blocks
  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(server_sock) = tcp.accept(listener, timeout)
      let assert Ok(_) = tcp.send(server_sock, <<"world":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(<<"world":utf8>>) = tcp.receive(socket, 5, net.infinity)

  // Wait for the sender process to finish
  let assert Ok(_) = process.receive(test_subject, 1000)

  let assert Ok(_) = tcp.shutdown(socket)
}

pub fn receive_forever_closed_test() {
  let #(socket, listener) = connected_pair()

  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(server_sock) = tcp.accept(listener, timeout)
      tcp.close(server_sock)
    })

  let assert Error(tcp.Closed) = tcp.receive(socket, 1, net.infinity)
}

// ---------- close ---------- //

pub fn close_test() {
  let #(socket, listener) = connected_pair()

  assert Nil == tcp.close(socket)
  assert Nil == tcp.close(socket)

  assert Nil == tcp.close(listener)
  assert Nil == tcp.close(listener)
}

// ---------- shutdown ---------- //

pub fn shutdown_test() {
  let #(socket, _listener) = connected_pair()

  let assert Ok(Nil) = tcp.shutdown(socket)
}

pub fn shutdown_closed_test() {
  let #(socket, listener) = connected_pair()

  // Close the underlying port entirely so shutdown will fail
  assert Nil == tcp.close(socket)
  assert Nil == tcp.close(listener)

  let assert Error(_posix) = tcp.shutdown(socket)
}

// Creates a TCP listener on an OS-assigned port, connects a client socket
// to it, and returns the client socket along with the listener port
fn connected_pair() -> #(Tcp, Tcp) {
  let assert Ok(port) = net.port(0)

  let assert Ok(listener) = tcp.listen(port, net.Ipv4Address(127, 0, 0, 1))

  let assert Ok(port_num) = tcp.port(listener)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)
  let assert Ok(socket) =
    address
    |> tcp.new(port_num)
    |> tcp.connect

  #(socket, listener)
}
