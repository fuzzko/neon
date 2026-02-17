import lumen

pub fn port(socket: lumen.Socket) -> Result(Int, Nil) {
  inet_port_(socket)
}

@external(erlang, "lumen_ffi", "port")
fn inet_port_(socket: lumen.Socket) -> Result(Int, Nil)
