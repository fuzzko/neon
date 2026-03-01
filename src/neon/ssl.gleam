import gleam/erlang/charlist.{type Charlist}
import neon/net
import neon/tcp.{type Tcp}

/// An SSL/TLS socket.
pub type Ssl

/// TLS alert descriptions as defined the [erlang ssl module documentation][1].
///
/// [1]: https://www.erlang.org/doc/apps/ssl/ssl.html#t:tls_alert/0
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

/// Errors that can occur during SSL/TLS operations.
pub type SslError {
  /// The connection was closed.
  Closed
  /// The operation timed out.
  Timeout
  /// A POSIX error.
  Posix(net.Posix)
  /// A TLS alert.
  TlsAlert(TlsAlert, String)
  /// A generic SSL error with a description.
  SslError(String)
}

type VerifyValue {
  VerifyNone
  VerifyPeer
}

type Verify {
  Verify(VerifyValue)
}

type Connect {
  Open(host: String, port: net.Port)
  Upgrade(socket: Tcp, host: String)
}

/// Options for establishing an SSL/TLS connection.
pub opaque type ConnectOptions {
  ConnectOptions(connect: Connect, verify: Verify, timeout: net.Timeout)
}

/// Creates connection options for a fresh SSL/TLS connection to the given
/// host and port.
///
/// Defaults to `verify_peer` and an infinite timeout.
pub fn new(host: String, port: net.Port) -> ConnectOptions {
  let connect = Open(host:, port:)

  ConnectOptions(connect:, verify: Verify(VerifyPeer), timeout: net.infinity)
}

/// Creates connection options to upgrade an existing TCP socket to SSL/TLS.
///
/// The `host` is used for Server Name Indication (SNI). Defaults to
/// `verify_peer` and an infinite timeout.
pub fn from_tcp(socket: Tcp, host: String) -> ConnectOptions {
  let connect = Upgrade(socket:, host:)

  ConnectOptions(connect:, verify: Verify(VerifyPeer), timeout: net.infinity)
}

/// Disables certificate verification.
///
/// This is insecure and should only be used for testing or when connecting
/// to hosts with self-signed certificates.
pub fn verify_none(opts: ConnectOptions) -> ConnectOptions {
  ConnectOptions(..opts, verify: Verify(VerifyNone))
}

/// Enables certificate verification against the system CA store.
///
/// This is the default.
pub fn verify_peer(opts: ConnectOptions) -> ConnectOptions {
  ConnectOptions(..opts, verify: Verify(VerifyPeer))
}

/// Sets the connection timeout.
pub fn timeout(opts: ConnectOptions, timeout: net.Timeout) -> ConnectOptions {
  ConnectOptions(..opts, timeout:)
}

/// Establishes an SSL/TLS connection using the given options.
///
/// This either opens a new connection or upgrades an existing TCP socket,
/// depending on whether `new` or `from_tcp` was used to create the options.
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

/// Sends data over an SSL/TLS socket.
pub fn send(socket: Ssl, payload: BitArray) -> Result(Nil, SslError) {
  ssl_send_(socket, payload)
}

/// Receives data from an SSL/TLS socket.
///
/// The `length` parameter specifies the number of bytes to receive. Use `0`
/// to receive whatever data is available. Must be non-negative.
pub fn receive(
  socket: Ssl,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, SslError) {
  case length >= 0 {
    True -> ssl_receive_(socket, length, timeout)
    False -> Error(SslError("Length must be positive"))
  }
}

/// Shuts down the SSL/TLS connection for both reading and writing.
pub fn shutdown(socket: Ssl) -> Result(Nil, SslError) {
  ssl_shutdown_(socket)
}

/// Closes an SSL/TLS socket.
pub fn close(socket: Ssl) -> Result(Nil, SslError) {
  ssl_close_(socket)
}

/// Starts the SSL application and its dependencies.
///
/// Must be called before any SSL/TLS operations. This function is
/// idempotent and can safely be called multiple times.
@external(erlang, "neon_ffi", "ssl_start")
pub fn start() -> Result(Nil, SslError)

/// Returns the port number assigned to an SSL socket by the operating system.
pub fn port(socket: Ssl) -> Result(net.Port, SslError) {
  ssl_port_(socket)
}

@external(erlang, "neon_ffi", "ssl_upgrade")
fn ssl_upgrade_(
  socket: Tcp,
  host: Charlist,
  verify: Verify,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "neon_ffi", "ssl_connect")
fn ssl_connect_(
  host: Charlist,
  port: Int,
  verify: Verify,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "neon_ffi", "ssl_send")
fn ssl_send_(socket: Ssl, payload: BitArray) -> Result(Nil, SslError)

@external(erlang, "neon_ffi", "ssl_recv")
fn ssl_receive_(
  socket: Ssl,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, SslError)

@external(erlang, "neon_ffi", "ssl_shutdown")
fn ssl_shutdown_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "neon_ffi", "ssl_close")
fn ssl_close_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "neon_ffi", "ssl_port")
fn ssl_port_(socket: Ssl) -> Result(net.Port, SslError)
