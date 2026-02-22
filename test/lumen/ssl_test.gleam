import gleam/erlang/process
import lumen/net
import lumen/ssl
import lumen/tcp
import lumen/testing

const host = "127.0.0.1"

// ---------- upgrade ---------- //

pub fn upgrade_test() {
  let #(cert, rsa_pk, ca_certs) = testing.pkix_test_data()

  let #(client_tcp, server_ssl) = testing.tcp_connected_pair()

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(listener) = tcp.accept(server_ssl, 5000)

      let assert Ok(_server_ssl) =
        testing.ssl_handshake(listener, cert, rsa_pk, ca_certs, 5000)
      process.send(test_subject, Nil)
    })

  let assert Ok(_ssl_socket) = ssl.upgrade(client_tcp, "127.0.0.1", False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- connect ---------- //

pub fn connect_test() {
  let #(cert, rsa_pk, ca_certs) = testing.pkix_test_data()

  testing.start_ssl_server()

  let assert Ok(listener) =
    tcp.ListenOptions(port: 0, ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(listener)

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(accepted) = tcp.accept(listener, 5000)

      let assert Ok(_server_ssl) =
        testing.ssl_handshake(accepted, cert, rsa_pk, ca_certs, 5000)
      process.send(test_subject, Nil)
    })

  let assert Ok(_ssl_socket) = ssl.connect(host, port_num, False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

pub fn upgrade_error_test() {
  let assert Ok(listener) =
    tcp.ListenOptions(port: 0, ip_address: net.Ipv4Address(127, 0, 0, 1))
    |> tcp.listen

  let assert Ok(port_num) = tcp.port(listener)

  let test_subject = process.new_subject()
  let _pid =
    process.spawn(fn() {
      let assert Ok(accepted) = tcp.accept(listener, 5000)

      let _ = tcp.close(accepted)
      process.send(test_subject, Nil)
    })

  let assert Ok(socket) = tcp.connect(host, port_num, net.Ipv4)

  let assert Error(ssl.Closed) = ssl.upgrade(socket, "127.0.0.1", False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- send ---------- //

pub fn send_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(_) = ssl.send(ssl_socket, <<"hello ssl":utf8>>)
  let assert Ok(_) = ssl.shutdown(ssl_socket)
}

pub fn send_closed_test() {
  let #(ssl_socket, _server_ssl) = testing.ssl_connected_pair()

  let assert Ok(_) = ssl.shutdown(ssl_socket)
  let assert Error(_) = ssl.send(ssl_socket, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  // Server sends data over SSL
  let assert Ok(_) = ssl.send(server_ssl, <<"hello ssl":utf8>>)

  let assert Ok(<<"hello ssl":utf8>>) = ssl.receive(ssl_socket, 9, 1000)
}

pub fn receive_timeout_test() {
  let #(ssl_socket, server_ssl) = testing.ssl_connected_pair()

  // No data is sent, so receive should time out
  let assert Error(ssl.Timeout) = ssl.receive(ssl_socket, 1, 100)

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

  let assert Ok(<<"world ssl":utf8>>) = ssl.receive_forever(ssl_socket, 9)

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
