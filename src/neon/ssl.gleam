import gleam/erlang/charlist.{type Charlist}
import gleam/option.{type Option, None, Some}
import neon/net
import neon/tcp.{type Tcp}

/// An SSL/TLS socket.
pub type Ssl

/// A private key for SSL/TLS server authentication.
pub opaque type PrivateKey {
  /// An RSA private key in DER-encoded binary format.
  RsaPrivateKey(BitArray)
  /// An EC private key in DER-encoded binary format.
  EcPrivateKey(BitArray)
}

/// Creates an RSA private key from a DER-encoded binary.
pub fn rsa_private_key(key: BitArray) -> PrivateKey {
  RsaPrivateKey(key)
}

/// Creates an EC private key from a DER-encoded binary.
pub fn ec_private_key(key: BitArray) -> PrivateKey {
  EcPrivateKey(key)
}

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
      |> ssl_connect_(port, opts.verify, opts.timeout)
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
@external(erlang, "ssl_ffi", "start")
pub fn start() -> Result(Nil, SslError)

/// Returns the port number assigned to an SSL socket by the operating system.
pub fn port(socket: Ssl) -> Result(net.Port, SslError) {
  ssl_port_(socket)
}

/// Options for performing a server-side TLS handshake.
///
/// Create with `handshake_options`, then optionally configure with
/// `cacerts` and `handshake_timeout` before passing to `handshake`.
pub opaque type HandshakeOptions {
  HandshakeOptions(
    cert: BitArray,
    key: PrivateKey,
    cacerts: Option(List(BitArray)),
    timeout: net.Timeout,
  )
}

/// Creates handshake options with the given certificate and private key.
///
/// The certificate should be a DER-encoded binary. Defaults to no CA
/// certificates and an infinite timeout.
pub fn handshake_options(cert: BitArray, key: PrivateKey) -> HandshakeOptions {
  HandshakeOptions(cert:, key:, cacerts: None, timeout: net.infinity)
}

/// Sets the CA certificates for client certificate verification.
pub fn cacerts(
  opts: HandshakeOptions,
  certs: List(BitArray),
) -> HandshakeOptions {
  HandshakeOptions(..opts, cacerts: Some(certs))
}

/// Sets the handshake timeout.
pub fn handshake_timeout(
  opts: HandshakeOptions,
  timeout: net.Timeout,
) -> HandshakeOptions {
  HandshakeOptions(..opts, timeout:)
}

/// Creates an SSL listen socket bound to the given port and IP address.
pub fn listen(
  port: net.Port,
  ip_address: net.IpAddress,
) -> Result(Ssl, SslError) {
  ssl_listen_(port, ip_address)
}

/// Accepts an incoming connection on an SSL listen socket.
///
/// Returns a transport socket that has not yet completed the TLS
/// handshake. Call `handshake` to complete the TLS negotiation.
pub fn accept(socket: Ssl, timeout: net.Timeout) -> Result(Ssl, SslError) {
  ssl_transport_accept_(socket, timeout)
}

/// Performs the server-side TLS handshake on a transport socket
/// returned by `accept`.
pub fn handshake(socket: Ssl, opts: HandshakeOptions) -> Result(Ssl, SslError) {
  ssl_handshake_(socket, opts.cert, opts.key, opts.cacerts, opts.timeout)
}

/// Performs a server-side TLS handshake on a raw TCP socket.
///
/// This is the server-side counterpart to `from_tcp` and is used for
/// START-TLS upgrades where an existing TCP connection is promoted to TLS.
pub fn handshake_from_tcp(
  socket: Tcp,
  opts: HandshakeOptions,
) -> Result(Ssl, SslError) {
  ssl_handshake_tcp_(socket, opts.cert, opts.key, opts.cacerts, opts.timeout)
}

@external(erlang, "ssl_ffi", "upgrade")
fn ssl_upgrade_(
  socket: Tcp,
  host: Charlist,
  verify: Verify,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "ssl_ffi", "connect")
fn ssl_connect_(
  host: Charlist,
  port: net.Port,
  verify: Verify,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "ssl_ffi", "send")
fn ssl_send_(socket: Ssl, payload: BitArray) -> Result(Nil, SslError)

@external(erlang, "ssl_ffi", "recv")
fn ssl_receive_(
  socket: Ssl,
  length: Int,
  timeout: net.Timeout,
) -> Result(BitArray, SslError)

@external(erlang, "ssl_ffi", "shutdown")
fn ssl_shutdown_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "ssl_ffi", "close")
fn ssl_close_(socket: Ssl) -> Result(Nil, SslError)

@external(erlang, "ssl_ffi", "port")
fn ssl_port_(socket: Ssl) -> Result(net.Port, SslError)

@external(erlang, "ssl_ffi", "listen")
fn ssl_listen_(
  port: net.Port,
  ip_address: net.IpAddress,
) -> Result(Ssl, SslError)

@external(erlang, "ssl_ffi", "transport_accept")
fn ssl_transport_accept_(
  socket: Ssl,
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "ssl_ffi", "handshake")
fn ssl_handshake_(
  socket: Ssl,
  cert: BitArray,
  key: PrivateKey,
  cacerts: Option(List(BitArray)),
  timeout: net.Timeout,
) -> Result(Ssl, SslError)

@external(erlang, "ssl_ffi", "handshake")
fn ssl_handshake_tcp_(
  socket: Tcp,
  cert: BitArray,
  key: PrivateKey,
  cacerts: Option(List(BitArray)),
  timeout: net.Timeout,
) -> Result(Ssl, SslError)
