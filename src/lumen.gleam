import gleam/result
import lumen/inet
import lumen/ssl.{type Ssl}
import lumen/tcp.{type Tcp}

pub opaque type Socket {
  TcpSocket(socket: Tcp)
  SslSocket(socket: Ssl)
}

pub fn connect(
  host: String,
  port: Int,
  ip_version: inet.IpVersion,
) -> Result(Socket, inet.PosixError) {
  host
  |> tcp.connect(port, ip_version)
  |> result.map(TcpSocket)
}

pub fn to_ssl(
  socket: Socket,
  host: String,
  verified: Bool,
) -> Result(Socket, inet.PosixError) {
  case socket {
    TcpSocket(socket) -> {
      socket
      |> ssl.upgrade(host, verified)
      |> result.map(SslSocket)
    }
    SslSocket(_) -> Ok(socket)
  }
}

pub fn send(
  socket: Socket,
  payload: BitArray,
) -> Result(Socket, inet.PosixError) {
  case socket {
    TcpSocket(socket) -> {
      tcp.send(socket, payload)
      |> result.map(TcpSocket)
    }
    SslSocket(socket) -> {
      ssl.send(socket, payload)
      |> result.map(SslSocket)
    }
  }
}

pub fn receive(
  socket: Socket,
  length: Int,
  timeout: Int,
) -> Result(BitArray, inet.PosixError) {
  case socket {
    TcpSocket(socket) -> tcp.receive(socket, length, timeout)
    SslSocket(socket) -> ssl.receive(socket, length, timeout)
  }
}

pub fn receive_forever(
  socket: Socket,
  length: Int,
) -> Result(BitArray, inet.PosixError) {
  case socket {
    TcpSocket(socket) -> tcp.receive_forever(socket, length)
    SslSocket(socket) -> ssl.receive_forever(socket, length)
  }
}

pub fn shutdown(socket: Socket) -> Result(Nil, inet.PosixError) {
  case socket {
    TcpSocket(socket) -> tcp.shutdown(socket)
    SslSocket(socket) -> ssl.shutdown(socket)
  }
}
