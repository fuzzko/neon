pub type IpAddress {
  Ipv4Address(Int, Int, Int, Int)
  Ipv6Address(Int, Int, Int, Int, Int, Int, Int, Int)
}

pub type IpVersion {
  Ipv4
  Ipv6
}

pub opaque type Port {
  Port(Int)
}

pub fn port(num: Int) -> Result(Port, Nil) {
  case num >= 0, num <= 65_535 {
    True, True -> Ok(Port(num))
    _, _ -> Error(Nil)
  }
}

pub fn port_to_int(port: Port) -> Int {
  let Port(num) = port

  num
}

pub type Timeout {
  Timeout(Int)
  Infinity
}

// https://www.erlang.org/doc/apps/kernel/inet.html#module-posix-error-codes
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
  Espipe
  Esrch
  Estale
  Etxtbsy
  Exdev
}

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
    Espipe -> "espipe"
    Esrch -> "esrch"
    Estale -> "estale"
    Etxtbsy -> "etxtbsy"
    Exdev -> "exdev"
  }
}
