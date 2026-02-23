import gleam/result
import lumen/net
import lumen/tcp.{type Tcp}

pub type Ssl

pub type TlsAlert {
  CloseNotify
  UnexpectedMessage
  BadRecordMac
  RecordOverflow
  HandshakeFailure
  BadCertificate
  UnsupportedCertificate
  CertificateRevoked
  CertificateExpired
  CertificateUnknown
  IllegalParameter
  UnknownCa
  AccessDenied
  DecodeError
  DecryptError
  ExportRestriction
  ProtocolVersion
  InsufficientSecurity
  InternalError
  InappropriateFallback
  UserCanceled
  NoRenegotiation
  UnsupportedExtension
  CertificateUnobtainable
  UnrecognizedName
  BadCertificateStatusResponse
  BadCertificateHashValue
  UnknownPskIdentity
  NoApplicationProtocol
}

pub type SslError {
  Closed
  Timeout
  InvalidOptions
  Posix(net.Posix)
  TlsAlert(TlsAlert, String)
  SslError(String)
}

pub fn upgrade(
  socket: Tcp,
  host: String,
  verified: Bool,
  timeout: net.Timeout,
) -> Result(Ssl, SslError) {
  ssl_upgrade_(socket, host, verified, timeout)
}

pub fn connect(
  host: String,
  port: net.Port,
  verified: Bool,
  timeout: net.Timeout,
) -> Result(Ssl, SslError) {
  ssl_connect_(host, net.port_to_int(port), verified, timeout)
}

pub fn send(socket: Ssl, payload: BitArray) -> Result(Nil, SslError) {
  ssl_send_(socket, payload)
}

pub fn receive(
  socket: Ssl,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, SslError) {
  ssl_receive_(socket, length, timeout)
}

pub fn shutdown(socket: Ssl) -> Result(Nil, SslError) {
  ssl_shutdown_(socket)
}

pub fn close(socket: Ssl) -> Result(Nil, SslError) {
  ssl_close_(socket)
}

pub fn port(socket: Ssl) -> Result(net.Port, SslError) {
  case ssl_port_(socket) {
    Ok(num) -> {
      net.port(num)
      |> result.map_error(fn(_) { SslError("invalid port") })
    }
    Error(ssl_err) -> Error(ssl_err)
  }
}

@external(erlang, "lumen_ffi", "ssl_upgrade")
fn ssl_upgrade_(
  socket: Tcp,
  host: String,
  verified: Bool,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "lumen_ffi", "ssl_connect")
fn ssl_connect_(
  host: String,
  port: Int,
  verified: Bool,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "lumen_ffi", "ssl_send")
fn ssl_send_(socket: Ssl, payload: BitArray) -> Result(Nil, SslError)

@external(erlang, "lumen_ffi", "ssl_recv")
fn ssl_receive_(
  socket: Ssl,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, SslError)

@external(erlang, "lumen_ffi", "ssl_shutdown")
fn ssl_shutdown_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "lumen_ffi", "ssl_close")
fn ssl_close_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "lumen_ffi", "ssl_port")
fn ssl_port_(socket: Ssl) -> Result(Int, SslError)
