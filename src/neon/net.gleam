import gleam/erlang/charlist.{type Charlist}
import gleam/option.{type Option, None, Some}

/// A network address, either a hostname or an IP address.
pub opaque type Address {
  Hostname(String)
  IpAddress(IpAddress)
}

@internal
pub fn address_to_ip_version(address: Address) -> Option(IpVersion) {
  case address {
    Hostname(_) -> None
    IpAddress(Ipv4Address(..)) -> Some(Ipv4)
    IpAddress(Ipv6Address(..)) -> Some(Ipv6)
  }
}

/// Creates an address from a hostname string.
pub fn hostname(name: String) -> Address {
  Hostname(name)
}

/// Creates an address from an IP address.
pub fn ip_address(addr: IpAddress) -> Address {
  IpAddress(addr)
}

/// An IPv4 or IPv6 address.
///
/// This type is opaque. Use `ipv4_address`, `ipv6_address`, or
/// `parse_ip_address` to construct values.
pub opaque type IpAddress {
  Ipv4Address(Int, Int, Int, Int)
  Ipv6Address(Int, Int, Int, Int, Int, Int, Int, Int)
}

/// Parses a string as an IP address.
///
/// Accepts both IPv4 (e.g. `"127.0.0.1"`) and IPv6 (e.g. `"::1"`) formats.
pub fn parse_ip_address(address: String) -> Result(IpAddress, Posix) {
  address
  |> charlist.from_string
  |> inet_parse_address
}

/// Converts an IP address to its string representation.
pub fn ip_address_to_string(address: IpAddress) -> String {
  inet_ntoa(address)
}

/// Creates an IPv4 address from four octets.
///
/// Each octet must be in the range 0-255. Returns `Error(Nil)` if any
/// octet is out of range.
pub fn ipv4_address(a: Int, b: Int, c: Int, d: Int) -> Result(IpAddress, Nil) {
  case
    a >= 0 && a <= 255,
    b >= 0 && b <= 255,
    c >= 0 && c <= 255,
    d >= 0 && d <= 255
  {
    True, True, True, True -> Ok(Ipv4Address(a, b, c, d))
    _, _, _, _ -> Error(Nil)
  }
}

/// Creates an IPv6 address from eight 16-bit groups.
///
/// Each group must be in the range 0-65535. Returns `Error(Nil)` if any
/// group is out of range.
///
/// ```gleam
/// // The loopback address ::1
/// let assert Ok(addr) = ipv6_address(0, 0, 0, 0, 0, 0, 0, 1)
///
/// // fe80::1 (link-local)
/// let assert Ok(addr) = ipv6_address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
///
/// // 2001:db8::1 (documentation range)
/// let assert Ok(addr) = ipv6_address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
/// ```
pub fn ipv6_address(
  a: Int,
  b: Int,
  c: Int,
  d: Int,
  e: Int,
  f: Int,
  g: Int,
  h: Int,
) -> Result(IpAddress, Nil) {
  case
    a >= 0 && a <= 65_535,
    b >= 0 && b <= 65_535,
    c >= 0 && c <= 65_535,
    d >= 0 && d <= 65_535,
    e >= 0 && e <= 65_535,
    f >= 0 && f <= 65_535,
    g >= 0 && g <= 65_535,
    h >= 0 && h <= 65_535
  {
    True, True, True, True, True, True, True, True ->
      Ok(Ipv6Address(a, b, c, d, e, f, g, h))
    _, _, _, _, _, _, _, _ -> Error(Nil)
  }
}

/// Returns the IP version of an IP address.
pub fn ip_address_version(address: IpAddress) -> IpVersion {
  case address {
    Ipv4Address(..) -> Ipv4
    Ipv6Address(..) -> Ipv6
  }
}

/// The IP version to use for a socket.
pub type IpVersion {
  Ipv4
  Ipv6
}

/// A port number in the range 0-65535.
///
/// This type is opaque. Use `port` to construct values and `port_to_int`
/// to extract the underlying integer.
pub opaque type Port {
  Port(Int)
}

/// Creates a port from an integer.
///
/// The value must be in the range 0-65535. Returns `Error(Nil)` if the
/// value is out of range.
pub fn port(num: Int) -> Result(Port, Nil) {
  case num >= 0, num <= 65_535 {
    True, True -> Ok(Port(num))
    _, _ -> Error(Nil)
  }
}

/// Returns the integer value of a port.
pub fn port_to_int(port: Port) -> Int {
  let Port(num) = port

  num
}

/// A timeout value for socket operations.
///
/// This type is opaque. Use `timeout` to create a finite timeout or
/// `infinity` for no timeout.
pub opaque type Timeout {
  Timeout(Int)
  Infinity
}

/// Creates a timeout from a number of milliseconds.
///
/// The value must be non-negative. Returns `Error(Nil)` if the value
/// is negative.
pub fn timeout(num: Int) -> Result(Timeout, Nil) {
  case num >= 0 {
    True -> Ok(Timeout(num))
    False -> Error(Nil)
  }
}

/// An infinite timeout.
pub const infinity = Infinity

/// POSIX error codes returned by the operating system.
///
/// See the [Erlang inet documentation](https://www.erlang.org/doc/apps/kernel/inet.html#module-posix-error-codes)
/// for descriptions of each error code.
pub type Posix {
  Eaddrinuse
  Eaddrnotavail
  Eafnosupport
  Ealready
  Econnaborted
  Econnrefused
  Econnreset
  Edestaddrreq
  Ehostdown
  Ehostunreach
  Einprogress
  Eisconn
  Emsgsize
  Enetdown
  Enetreset
  Enetunreach
  Enopkg
  Enoprotoopt
  Enotconn
  Enotty
  Enotsock
  Eproto
  Eprotonosupport
  Eprototype
  Esocktnosupport
  Etimedout
  Ewouldblock
  Exbadport
  Exbadseq
  Nxdomain
  Eacces
  Eagain
  Ebadf
  Ebadmsg
  Ebusy
  Edeadlk
  Edeadlock
  Edquot
  Eexist
  Efault
  Efbig
  Eftype
  Eintr
  Einval
  Eio
  Eisdir
  Eloop
  Emfile
  Emlink
  Emultihop
  Enametoolong
  Enfile
  Enobufs
  Enodev
  Enolck
  Enolink
  Enoent
  Enomem
  Enospc
  Enosr
  Enostr
  Enosys
  Enotblk
  Enotdir
  Enotsup
  Enxio
  Eopnotsupp
  Eoverflow
  Eperm
  Epipe
  Erange
  Erofs
  Eshutdown
  Espipe
  Esrch
  Estale
  Etxtbsy
  Exdev
}

/// Converts a POSIX error code to its string representation.
pub fn posix_to_string(code: Posix) -> String {
  case code {
    Eaddrinuse -> "eaddrinuse"
    Eaddrnotavail -> "eaddrnotavail"
    Eafnosupport -> "eafnosupport"
    Ealready -> "ealready"
    Econnaborted -> "econnaborted"
    Econnrefused -> "econnrefused"
    Econnreset -> "econnreset"
    Edestaddrreq -> "edestaddrreq"
    Ehostdown -> "ehostdown"
    Ehostunreach -> "ehostunreach"
    Einprogress -> "einprogress"
    Eisconn -> "eisconn"
    Emsgsize -> "emsgsize"
    Enetdown -> "enetdown"
    Enetreset -> "enetreset"
    Enetunreach -> "enetunreach"
    Enopkg -> "enopkg"
    Enoprotoopt -> "enoprotoopt"
    Enotconn -> "enotconn"
    Enotty -> "enotty"
    Enotsock -> "enotsock"
    Eproto -> "eproto"
    Eprotonosupport -> "eprotonosupport"
    Eprototype -> "eprototype"
    Esocktnosupport -> "esocktnosupport"
    Etimedout -> "etimedout"
    Ewouldblock -> "ewouldblock"
    Exbadport -> "exbadport"
    Exbadseq -> "exbadseq"
    Nxdomain -> "nxdomain"
    Eacces -> "eacces"
    Eagain -> "eagain"
    Ebadf -> "ebadf"
    Ebadmsg -> "ebadmsg"
    Ebusy -> "ebusy"
    Edeadlk -> "edeadlk"
    Edeadlock -> "edeadlock"
    Edquot -> "edquot"
    Eexist -> "eexist"
    Efault -> "efault"
    Efbig -> "efbig"
    Eftype -> "eftype"
    Eintr -> "eintr"
    Einval -> "einval"
    Eio -> "eio"
    Eisdir -> "eisdir"
    Eloop -> "eloop"
    Emfile -> "emfile"
    Emlink -> "emlink"
    Emultihop -> "emultihop"
    Enametoolong -> "enametoolong"
    Enfile -> "enfile"
    Enobufs -> "enobufs"
    Enodev -> "enodev"
    Enolck -> "enolck"
    Enolink -> "enolink"
    Enoent -> "enoent"
    Enomem -> "enomem"
    Enospc -> "enospc"
    Enosr -> "enosr"
    Enostr -> "enostr"
    Enosys -> "enosys"
    Enotblk -> "enotblk"
    Enotdir -> "enotdir"
    Enotsup -> "enotsup"
    Enxio -> "enxio"
    Eopnotsupp -> "eopnotsupp"
    Eoverflow -> "eoverflow"
    Eperm -> "eperm"
    Epipe -> "epipe"
    Erange -> "erange"
    Erofs -> "erofs"
    Eshutdown -> "eshutdown"
    Espipe -> "espipe"
    Esrch -> "esrch"
    Estale -> "estale"
    Etxtbsy -> "etxtbsy"
    Exdev -> "exdev"
  }
}

@external(erlang, "neon_ffi", "inet_parse_address")
fn inet_parse_address(address: Charlist) -> Result(IpAddress, Posix)

@external(erlang, "neon_ffi", "inet_ntoa")
fn inet_ntoa(address: IpAddress) -> String
