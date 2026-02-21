import gleam/erlang/process
import lumen/net
import lumen/udp

// ---------- connect ---------- //

const host = "127.0.0.1"

pub fn open_test() {
  let assert Ok(_sock) = udp.open(0)
}

pub fn port_test() {
  let assert Ok(sock) = udp.open(0)
  let assert Ok(port_num) = udp.port(sock)

  assert port_num > 0
}

pub fn connect_test() {
  let assert Ok(sock) = udp.open(0)
  let assert Ok(port_num) = udp.port(sock)

  let assert Ok(Nil) = udp.connect(sock, host, port_num)
}

pub fn send_test() {
  let assert Ok(sock) = udp.open(0)
  let assert Ok(port_num) = udp.port(sock)

  let assert Ok(Nil) = udp.connect(sock, host, port_num)

  let assert Ok(Nil) = udp.send(sock, <<"hello":utf8>>)
}

pub fn send_closed_test() {
  let assert Ok(sock) = udp.open(0)
  let assert Ok(port_num) = udp.port(sock)

  let assert Ok(Nil) = udp.connect(sock, host, port_num)
  let assert Ok(Nil) = udp.close(sock)

  let assert Error(_) = udp.send(sock, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  // Open a receiver socket and a sender socket
  let assert Ok(receiver) = udp.open(0)
  let assert Ok(receiver_port) = udp.port(receiver)

  let assert Ok(sender) = udp.open(0)
  let assert Ok(Nil) = udp.connect(sender, host, receiver_port)
  let assert Ok(Nil) = udp.send(sender, <<"hello":utf8>>)

  let assert Ok(udp.ReceiveData(
    ip_address: net.Ipv4Address(127, 0, 0, 1),
    port: _sender_port,
    payload: <<"hello":utf8>>,
  )) = udp.receive(receiver, 0, 1000)
}

pub fn receive_timeout_test() {
  let assert Ok(sock) = udp.open(0)

  // No data is sent, so receive should time out
  let assert Error(net.Timeout) = udp.receive(sock, 0, 100)
}

pub fn receive_forever_test() {
  let assert Ok(receiver) = udp.open(0)
  let assert Ok(receiver_port) = udp.port(receiver)
  let test_subject = process.new_subject()

  // Spawn a process that sends data, since receive_forever blocks
  let _pid =
    process.spawn(fn() {
      let assert Ok(sender) = udp.open(0)
      let assert Ok(Nil) = udp.connect(sender, host, receiver_port)
      let assert Ok(Nil) = udp.send(sender, <<"world":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(udp.ReceiveData(
    ip_address: net.Ipv4Address(127, 0, 0, 1),
    port: _sender_port,
    payload: <<"world":utf8>>,
  )) = udp.receive_forever(receiver, 0)

  // Wait for the sender process to finish
  let assert Ok(_) = process.receive(test_subject, 1000)
}

// ---------- close ---------- //

pub fn close_test() {
  let assert Ok(sock) = udp.open(0)

  let assert Ok(Nil) = udp.close(sock)
}

pub fn close_receive_test() {
  let assert Ok(sock) = udp.open(0)

  let assert Ok(Nil) = udp.close(sock)

  // Receiving on a closed socket should fail
  let assert Error(_) = udp.receive(sock, 0, 100)
}
