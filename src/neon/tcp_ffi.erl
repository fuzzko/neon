-module(tcp_ffi).

-export([
  tcp_accept/2,
  tcp_close/1,
  tcp_listen/2,
  tcp_connect/4,
  tcp_send/2,
  tcp_recv/3,
  tcp_shutdown/1
]).

tcp_connect(Address, Port, IpVersion, Timeout) ->
  Inet = ip_version_to_inet(IpVersion),

  Addr = case Address of
    {hostname, Hostname} -> unicode:characters_to_list(Hostname);
    {ip_address, {ipv4_address, A, B, C, D}} -> {A, B, C, D};
    {ip_address, {ipv6_address, A, B, C, D, E, F, G, H}} -> {A, B, C, D, E, F, G, H}
  end,

  T = normalise_timeout(Timeout),

  Opts = [
    binary,
    {packet, raw},
    {active, false},
    Inet
  ],

  Resp = gen_tcp:connect(Addr, Port, Opts, T),
  normalise_tcp(Resp).

ip_version_to_inet(ipv6) -> inet6;
ip_version_to_inet(ipv4) -> inet.

tcp_shutdown(TcpSocket) ->
  Shut = gen_tcp:shutdown(TcpSocket, read_write),
  normalise_tcp(Shut).

tcp_recv(TcpSocket, Size, Timeout) ->
  T = normalise_timeout(Timeout),
  Resp = gen_tcp:recv(TcpSocket, Size, T),
  normalise_tcp(Resp).

tcp_send(TcpSocket, Packet) ->
  Sent = gen_tcp:send(TcpSocket, Packet),
  normalise_tcp(Sent).

tcp_listen(Port, IpAddress) ->
  {Inet, Address} = ip_address_and_version(IpAddress),

  Options = [
    binary,
    {ip, Address},
    {packet, raw},
    {active, false},
    {reuseaddr, true},
    Inet
  ],
  Resp = gen_tcp:listen(Port, Options),
  normalise_tcp(Resp).

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.

tcp_accept(TcpSocket, Timeout) ->
  T = normalise_timeout(Timeout),
  Resp = gen_tcp:accept(TcpSocket, T),
  normalise_tcp(Resp).

tcp_close(TcpSocket) ->
  gen_tcp:close(TcpSocket),
  nil.

normalise_tcp(ok) -> {ok, nil};
normalise_tcp({ok, TcpSocket}) -> {ok, TcpSocket};
normalise_tcp({error, closed} = E) -> E;
normalise_tcp({error, timeout} = E) -> E;
normalise_tcp({error, system_limit} = E) -> E;
normalise_tcp({error, {timeout, _}}) -> {error, timeout};
normalise_tcp({error, Posix}) -> {error, {posix, Posix}}.

normalise_timeout(infinity) -> infinity;
normalise_timeout({timeout, Int}) -> Int.
