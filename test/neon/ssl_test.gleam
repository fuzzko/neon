import gleam/erlang/process
import gleam/result
import neon/net
import neon/ssl
import neon/tcp
import neon/testing

const host = "127.0.0.1"

// ---------- upgrade ---------- //

pub fn upgrade_test() {
  let #(cert, rsa_pk, ca_certs) = testing.pkix_test_data()

  let #(client_tcp, server_ssl) = testing.tcp_connected_pair()

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(listener) = tcp.accept(server_ssl, timeout)

      let assert Ok(_server_ssl) =
        testing.ssl_handshake(listener, cert, rsa_pk, ca_certs, 5000)
      process.send(test_subject, Nil)
    })

  let assert Ok(_ssl_socket) =
    ssl.from_tcp(client_tcp, "127.0.0.1")
    |> ssl.verify_none
    |> ssl.connect

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- connect ---------- //

pub fn connect_test() {
  let #(cert, rsa_pk, ca_certs) = testing.pkix_test_data()

  testing.start_ssl_server()

  let assert Ok(port) = net.port(0)

  let assert Ok(listener) =
    tcp.ListenOptions(ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen(port, _)

  let assert Ok(port_num) = tcp.port(listener)

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(accepted) = tcp.accept(listener, timeout)

      let assert Ok(_server_ssl) =
        testing.ssl_handshake(accepted, cert, rsa_pk, ca_certs, 5000)
      process.send(test_subject, Nil)
    })

  let assert Ok(_ssl_socket) =
    ssl.new(host, port_num)
    |> ssl.verify_none
    |> ssl.connect

  let assert Ok(_) = process.receive(test_subject, 5000)
}

pub fn connect_verify_peer_test() {
  let assert Ok(port) = net.port(443)

  let assert Ok(_ssl_socket) =
    ssl.new("gleam.run", port)
    |> ssl.verify_peer
    |> ssl.connect
}

pub fn connect_error_test() {
  testing.start_ssl_server()

  let assert Ok(port) = net.port(1)

  let assert Error(ssl.Posix(net.Econnrefused)) =
    ssl.new(host, port)
    |> ssl.connect
}

pub fn upgrade_error_test() {
  let assert Ok(port) = net.port(0)

  let assert Ok(listener) =
    tcp.ListenOptions(ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen(port, _)

  let assert Ok(port_num) = tcp.port(listener)

  let test_subject = process.new_subject()
  let _pid =
    process.spawn(fn() {
      let assert Ok(timeout) = net.timeout(5000)
      let assert Ok(accepted) = tcp.accept(listener, timeout)

      let _ = tcp.close(accepted)
      process.send(test_subject, Nil)
    })

  let assert Ok(address) =
    net.parse_ip_address(host)
    |> result.map(net.ip_address)

  let assert Ok(socket) =
    address
    |> tcp.new(port_num)
    |> tcp.connect

  let assert Error(ssl.Closed) =
    ssl.from_tcp(socket, "127.0.0.1")
    |> ssl.verify_none
    |> ssl.connect

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- send ---------- //

pub fn send_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.send(ssl_socket, <<"hello ssl":utf8>>)
  let assert Ok(Nil) = ssl.shutdown(ssl_socket)
}

pub fn send_closed_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(_) = ssl.shutdown(ssl_socket)
  process.sleep(50)
  let assert Error(ssl.Closed) = ssl.send(ssl_socket, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  // Server sends data over SSL
  let assert Ok(_) = ssl.send(server_ssl, <<"hello ssl":utf8>>)

  let assert Ok(timeout) = net.timeout(1000)
  let assert Ok(<<"hello ssl":utf8>>) = ssl.receive(ssl_socket, 9, timeout)
}

pub fn receive_timeout_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  // No data is sent, so receive should time out
  let assert Ok(timeout) = net.timeout(100)
  let assert Error(ssl.Timeout) = ssl.receive(ssl_socket, 1, timeout)

  let _ = ssl.close(server_ssl)
}

pub fn receive_forever_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()
  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(_) = ssl.send(server_ssl, <<"world ssl":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(<<"world ssl":utf8>>) = ssl.receive(ssl_socket, 9, net.infinity)

  let assert Ok(_) = process.receive(test_subject, 1000)
}

pub fn receive_closed_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.close(server_ssl)

  process.sleep(50)

  let assert Ok(timeout) = net.timeout(1000)
  let assert Error(ssl.Closed) = ssl.receive(ssl_socket, 1, timeout)
}

pub fn receive_forever_closed_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()
  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(Nil) = ssl.close(server_ssl)
      process.send(test_subject, Nil)
    })

  let assert Error(ssl.Closed) = ssl.receive(ssl_socket, 1, net.infinity)

  let assert Ok(_) = process.receive(test_subject, 1000)
}

// ---------- close ---------- //

pub fn close_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.close(ssl_socket)
  let assert Ok(Nil) = ssl.close(ssl_socket)

  let assert Ok(Nil) = ssl.close(server_ssl)
  let assert Ok(Nil) = ssl.close(server_ssl)
}

// ---------- shutdown ---------- //

pub fn shutdown_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.shutdown(ssl_socket)
}

pub fn shutdown_closed_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.close(server_ssl)

  process.sleep(50)

  let assert Error(ssl.Closed) = ssl.shutdown(ssl_socket)
}

// ---------- port ---------- //

pub fn port_test() {
  let #(client_ssl, server_ssl) = testing.ssl_connected_pair()

  let assert Ok(client_port) = ssl.port(client_ssl)
  assert net.port_to_int(client_port) > 0

  let assert Ok(server_port) = ssl.port(server_ssl)
  assert net.port_to_int(server_port) > 0
}

pub fn port_closed_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(Nil) = ssl.close(ssl_socket)

  let assert Error(ssl.Posix(_posix)) = ssl.port(ssl_socket)
}
