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
  SslError(String)
}

type VerifyValue {
  VerifyNone
  VerifyPeer
}

pub opaque type Verify {
  Verify(VerifyValue)
}

type Connect {
  Open(host: String, port: net.Port)
  Upgrade(socket: Tcp, host: String)
}

pub opaque type ConnectOptions {
  ConnectOptions(connect: Connect, verify: Verify, timeout: net.Timeout)
}

pub fn new(host: String, port: net.Port) -> ConnectOptions {
  let connect = Open(host:, port:)

  ConnectOptions(connect:, verify: Verify(VerifyPeer), timeout: net.infinity)
}

pub fn from_tcp(socket: Tcp, host: String) -> ConnectOptions {
  let connect = Upgrade(socket:, host:)

  ConnectOptions(connect:, verify: Verify(VerifyNone), timeout: net.infinity)
}

pub fn verify_none(opts: ConnectOptions) -> ConnectOptions {
  ConnectOptions(..opts, verify: Verify(VerifyNone))
}

pub fn verify_peer(opts: ConnectOptions) -> ConnectOptions {
  ConnectOptions(..opts, verify: Verify(VerifyPeer))
}

pub fn connect(opts: ConnectOptions) -> Result(Ssl, SslError) {
  case opts.connect {
    Open(host:, port:) ->
      host
      |> charlist.from_string
      |> ssl_connect_(net.port_to_int(port), opts.verify, opts.timeout)
    Upgrade(socket:, host:) -> {
      let host = charlist.from_string(host)

      ssl_upgrade_(socket, host, opts.verify, opts.timeout)
    }
  }
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

@external(erlang, "lumen_ffi", "ssl_start")
pub fn start() -> Result(Nil, SslError)

pub fn port(socket: Ssl) -> Result(net.Port, SslError) {
  case ssl_port_(socket) {
    Ok(num) -> {
      net.port(num)
      |> result.map_error(fn(_) { SslError("invalid port") })
    }
    Error(ssl_err) -> Error(ssl_err)
  }
}

@external(erlang, "lumen_ffi", "ssl_connect")
fn ssl_upgrade_(
  socket: Tcp,
  host: Charlist,
  verify: Verify,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "lumen_ffi", "ssl_connect")
fn ssl_connect_(
  host: Charlist,
  port: Int,
  verify: Verify,
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
