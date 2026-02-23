import gleam/erlang/process
import gleam/result
import lumen/net
import lumen/udp

// ---------- connect ---------- //

const host = "127.0.0.1"

pub fn open_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(_sock) = udp.open(port)
}

pub fn open_error_test() {
  let assert Ok(port) = net.port(1)
  // Port 1 is privileged so opening should fail
  let assert Error(udp.Posix(net.Eacces)) = udp.open(port)
}

pub fn port_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)
  let assert Ok(port) = udp.port(sock)

  assert net.port_to_int(port) > 0
}

pub fn connect_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)
  let assert Ok(port_num) = udp.port(sock)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(Nil) = udp.connect(sock, address, port_num)
}

pub fn connect_closed_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  udp.close(sock)

  let assert Ok(closed_port) = net.port(8000)
  let assert Error(_) = udp.connect(sock, address, closed_port)
}

pub fn send_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)
  let assert Ok(port_num) = udp.port(sock)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(Nil) = udp.connect(sock, address, port_num)

  let assert Ok(Nil) = udp.send(sock, <<"hello":utf8>>)
}

pub fn send_closed_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)
  let assert Ok(port_num) = udp.port(sock)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(Nil) = udp.connect(sock, address, port_num)

  udp.close(sock)

  let assert Error(_) = udp.send(sock, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  let assert Ok(port) = net.port(0)
  // Open a receiver socket and a sender socket
  let assert Ok(receiver) = udp.open(port)
  let assert Ok(receiver_port) = udp.port(receiver)

  let assert Ok(sender) = udp.open(port)
  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(Nil) = udp.connect(sender, address, receiver_port)
  let assert Ok(Nil) = udp.send(sender, <<"hello":utf8>>)

  let assert Ok(timeout) = net.timeout(1000)
  let assert Ok(udp.ReceiveData(
    ip_address: net.Ipv4Address(127, 0, 0, 1),
    port: _sender_port,
    payload: <<"hello":utf8>>,
  )) = udp.receive(receiver, 0, timeout)
}

pub fn receive_timeout_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)

  // No data is sent, so receive should time out
  let assert Ok(timeout) = net.timeout(100)
  let assert Error(udp.Timeout) = udp.receive(sock, 0, timeout)
}

pub fn receive_forever_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(receiver) = udp.open(port)
  let assert Ok(receiver_port) = udp.port(receiver)
  let test_subject = process.new_subject()

  // Spawn a process that sends data, since receive with Infinity blocks
  let _pid =
    process.spawn(fn() {
      let assert Ok(sender) = udp.open(port)
      let assert Ok(address) =
        net.parse_ip_address(host)
        |> result.map(net.ip_address)
      let assert Ok(Nil) = udp.connect(sender, address, receiver_port)
      let assert Ok(Nil) = udp.send(sender, <<"world":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(udp.ReceiveData(
    ip_address: net.Ipv4Address(127, 0, 0, 1),
    port: _sender_port,
    payload: <<"world":utf8>>,
  )) = udp.receive(receiver, 0, net.infinity)

  // Wait for the sender process to finish
  let assert Ok(_) = process.receive(test_subject, 1000)
}

pub fn receive_forever_closed_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)

  udp.close(sock)

  let assert Error(udp.Closed) = udp.receive(sock, 0, net.infinity)
}

// ---------- close ---------- //

pub fn close_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)

  udp.close(sock)
  udp.close(sock)
}

pub fn close_receive_test() {
  let assert Ok(port) = net.port(0)
  let assert Ok(sock) = udp.open(port)

  udp.close(sock)

  // Receiving on a closed socket should fail
  let assert Ok(timeout) = net.timeout(100)
  let assert Error(_) = udp.receive(sock, 0, timeout)
}
