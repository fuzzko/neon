import lumen

pub fn port(socket: lumen.Socket(a)) -> Result(Int, Nil) {
  inet_port_(socket)
}

@external(erlang, "lumen_ffi", "inet_port")
fn inet_port_(socket: lumen.Socket(a)) -> Result(Int, Nil)
