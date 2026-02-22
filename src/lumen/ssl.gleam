import gleam/erlang/charlist.{type Charlist}
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
  Other(String)
}

pub fn upgrade(
  socket: Tcp,
  host: String,
  verified: Bool,
) -> Result(Ssl, SslError) {
  ssl_upgrade_(socket, host, verified)
}

pub fn connect(
  host: String,
  port: net.Port,
  verified: Bool,
) -> Result(Ssl, SslError) {
  host
  |> charlist.from_string
  |> ssl_connect_(net.port_to_int(port), verified)
}

pub fn send(socket: Ssl, payload: BitArray) -> Result(Ssl, SslError) {
  ssl_send_(socket, payload)
  |> result.replace(socket)
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

@external(erlang, "lumen_ffi", "ssl_upgrade")
fn ssl_upgrade_(
  socket: Tcp,
  host: String,
  verified: Bool,
) -> Result(Ssl, SslError)

@external(erlang, "lumen_ffi", "ssl_connect")
fn ssl_connect_(
  host: Charlist,
  port: Int,
  verified: Bool,
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
