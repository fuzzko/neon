import gleam/erlang/process
import lumen
import lumen/inet
import lumen/tcp.{type Tcp}

// ---------- connect ---------- //

const host = "127.0.0.1"

pub fn connect_test() {
  let assert Ok(tcp_port) = tcp.listen(0)
  let assert Ok(port_num) = inet.port(tcp_port)

  let assert Ok(_socket) = tcp.connect(host, port_num, lumen.Ipv4)
}

pub fn connect_ipv6_test() {
  let assert Ok(tcp_port) = tcp.listen_ipv6(0)
  let assert Ok(port_num) = inet.port(tcp_port)

  let assert Ok(_socket) = tcp.connect("::1", port_num, lumen.Ipv6)
}

pub fn connect_error_test() {
  let assert Error(lumen.Econnrefused) = tcp.connect(host, 1, lumen.Ipv4)
}

// ---------- send ---------- //

pub fn send_test() {
  let #(socket, _listener) = connected_pair()

  let assert Ok(returned) = tcp.send(socket, <<"hello":utf8>>)
  let assert Ok(_) = tcp.shutdown(returned)
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
  let assert Ok(server_sock) = tcp.accept(listener, 1000)
  let assert Ok(_) = tcp.send(server_sock, <<"hello":utf8>>)

  let assert Ok(<<"hello":utf8>>) = tcp.receive(socket, 5, 1000)

  let assert Ok(_) = tcp.shutdown(socket)
}

pub fn receive_timeout_test() {
  let #(socket, _listener) = connected_pair()

  // No data is sent, so receive should time out
  let assert Error(lumen.Timeout) = tcp.receive(socket, 1, 100)

  let assert Ok(_) = tcp.shutdown(socket)
}

pub fn receive_forever_test() {
  let #(socket, listener) = connected_pair()
  let test_subject = process.new_subject()

  // Spawn a process that accepts and sends data, since receive_forever blocks
  let _pid =
    process.spawn(fn() {
      let assert Ok(server_sock) = tcp.accept(listener, 5000)
      let assert Ok(_) = tcp.send(server_sock, <<"world":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(<<"world":utf8>>) = tcp.receive_forever(socket, 5)

  // Wait for the sender process to finish
  let assert Ok(_) = process.receive(test_subject, 1000)

  let assert Ok(_) = tcp.shutdown(socket)
}

// ---------- shutdown ---------- //

pub fn shutdown_test() {
  let #(socket, _listener) = connected_pair()

  let assert Ok(Nil) = tcp.shutdown(socket)
}

pub fn shutdown_closed_test() {
  let #(socket, listener) = connected_pair()

  // Close the underlying port entirely so shutdown will fail
  let _ = tcp.close(socket)
  let _ = tcp.close(listener)

  let assert Error(_posix) = tcp.shutdown(socket)
}

// Creates a TCP listener on an OS-assigned port, connects a client socket
// to it, and returns the client socket along with the listener port
fn connected_pair() -> #(lumen.Socket(Tcp), lumen.Socket(Tcp)) {
  let assert Ok(listener) = tcp.listen(0)
  let assert Ok(port_num) = inet.port(listener)
  let assert Ok(socket) = tcp.connect(host, port_num, lumen.Ipv4)

  #(socket, listener)
}
