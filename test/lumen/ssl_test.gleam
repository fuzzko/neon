import gleam/erlang/process
import lumen
import lumen/ssl
import lumen/tcp

const host = "127.0.0.1"

// ---------- upgrade ---------- //

pub fn upgrade_test() {
  let data = pkix_test_data()

  let #(client_tcp, server_ssl) = tcp_connected_pair()

  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(listener) = tcp.accept(server_ssl, 5000)

      let assert Ok(_server_ssl) =
        ssl_handshake(
          listener,
          data.cert,
          data.rsa_private_key,
          data.ca_certs,
          5000,
        )
      process.send(test_subject, Nil)
    })

  let assert Ok(_ssl_socket) = ssl.upgrade(client_tcp, "127.0.0.1", False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

pub fn upgrade_error_test() {
  let assert Ok(listener) = tcp.listen(0)
  let assert Ok(port_num) = inet_port(listener)

  let test_subject = process.new_subject()
  let _pid =
    process.spawn(fn() {
      let assert Ok(accepted) = tcp.accept(listener, 5000)

      let _ = tcp.close(accepted)
      process.send(test_subject, Nil)
    })

  let assert Ok(socket) = tcp.connect(host, port_num, lumen.Ipv4)

  let assert Error(lumen.Closed) = ssl.upgrade(socket, "127.0.0.1", False)

  let assert Ok(_) = process.receive(test_subject, 5000)
}

// ---------- send ---------- //

pub fn send_test() {
  let #(ssl_socket, _server_ssl) = ssl_connected_pair()

  let assert Ok(_) = ssl.send(ssl_socket, <<"hello ssl":utf8>>)
  let assert Ok(_) = ssl.shutdown(ssl_socket)
}

pub fn send_closed_test() {
  let #(ssl_socket, _server_ssl) = ssl_connected_pair()

  let assert Ok(_) = ssl.shutdown(ssl_socket)
  let assert Error(lumen.Closed) = ssl.send(ssl_socket, <<"hello":utf8>>)
}

// ---------- receive ---------- //

pub fn receive_test() {
  let #(ssl_socket, server_ssl) = ssl_connected_pair()

  // Server sends data over SSL
  let assert Ok(_) = ssl.send(server_ssl, <<"hello ssl":utf8>>)

  let assert Ok(<<"hello ssl":utf8>>) = ssl.receive(ssl_socket, 9, 1000)
}

pub fn receive_timeout_test() {
  let #(ssl_socket, server_ssl) = ssl_connected_pair()

  // No data is sent, so receive should time out
  let assert Error(lumen.Timeout) = ssl.receive(ssl_socket, 1, 100)

  let _ = ssl.close(server_ssl)
}

pub fn receive_forever_test() {
  let #(ssl_socket, server_ssl) = ssl_connected_pair()
  let test_subject = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let assert Ok(_) = ssl.send(server_ssl, <<"world ssl":utf8>>)
      process.send(test_subject, Nil)
    })

  let assert Ok(<<"world ssl":utf8>>) = ssl.receive_forever(ssl_socket, 9)

  let assert Ok(_) = process.receive(test_subject, 1000)
}

// ---------- shutdown ---------- //

pub fn shutdown_test() {
  let #(ssl_socket, _server_ssl) = ssl_connected_pair()

  let assert Ok(Nil) = ssl.shutdown(ssl_socket)
}

pub fn shutdown_closed_test() {
  let #(ssl_socket, server_ssl) = ssl_connected_pair()

  let _ = ssl.close(server_ssl)

  process.sleep(50)

  let assert Error(lumen.Closed) = ssl.shutdown(ssl_socket)
}

// ---------- helpers ---------- //

fn tcp_connected_pair() -> #(lumen.Socket, lumen.Socket) {
  start_ssl_server()

  let assert Ok(server_ssl) = tcp.listen(0)

  let assert Ok(port) = inet_port(server_ssl)

  let assert Ok(client_tcp) = tcp.connect(host, port, lumen.Ipv4)

  #(client_tcp, server_ssl)
}

fn ssl_connected_pair() -> #(lumen.Socket, lumen.Socket) {
  let #(client_tcp, server_ssl) = tcp_connected_pair()
  let test_subject = process.new_subject()
  let data = pkix_test_data()

  let _pid =
    process.spawn(fn() {
      let assert Ok(listener) = tcp.accept(server_ssl, 5000)
      let assert Ok(server_ssl) =
        ssl_handshake(
          listener,
          data.cert,
          data.rsa_private_key,
          data.ca_certs,
          5000,
        )

      process.send(test_subject, server_ssl)

      process.receive_forever(process.new_subject())
    })

  let assert Ok(client_ssl) = ssl.upgrade(client_tcp, "127.0.0.1", False)
  let assert Ok(server_ssl) = process.receive(test_subject, 5000)

  #(client_ssl, server_ssl)
}

// ---------- erlang FFI for test infrastructure ---------- //

pub type PkixTestData {
  PkixTextData(
    cert: BitArray,
    rsa_private_key: BitArray,
    ca_certs: List(BitArray),
  )
}

@external(erlang, "ssl_test_ffi", "pkix_test_data")
fn pkix_test_data() -> PkixTestData

@external(erlang, "ssl_test_ffi", "start_ssl_server")
fn start_ssl_server() -> Nil

@external(erlang, "ssl_test_ffi", "ssl_handshake")
fn ssl_handshake(
  listener: lumen.Socket,
  cert: BitArray,
  rsa_private_key: BitArray,
  ca_certs: List(BitArray),
  timeout: Int,
) -> Result(lumen.Socket, lumen.PosixError)

@external(erlang, "inet", "port")
fn inet_port(port: lumen.Socket) -> Result(Int, Nil)
