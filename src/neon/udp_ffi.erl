-module(udp_ffi).

-export([
  udp_open/3,
  udp_connect/3,
  udp_send/2,
  udp_receive/3,
  udp_close/1
]).

udp_open(Port, MaybeIpAddress, IpVersion) ->
  case MaybeIpAddress of
    none ->
      Inet = ip_version_to_inet(IpVersion),
      Opts = [binary, {active, false}, Inet],
      normalise_udp(gen_udp:open(Port, Opts));
    {some, Addr} ->
      {Inet, Tuple} = ip_address_and_version(Addr),
      Opts = [binary, {active, false}, {ip, Tuple}, Inet],
      normalise_udp(gen_udp:open(Port, Opts))
  end.

udp_connect(UdpSocket, Address, Port) ->
  Addr = case Address of
    {hostname, Hostname} -> unicode:characters_to_list(Hostname);
    {ip_address, {ipv4_address, A, B, C, D}} -> {A, B, C, D};
    {ip_address, {ipv6_address, A, B, C, D, E, F, G, H}} -> {A, B, C, D, E, F, G, H}
  end,
  Resp = gen_udp:connect(UdpSocket, Addr, Port),
  normalise_udp(Resp).

udp_send(UdpSocket, Packet) ->
  Resp = gen_udp:send(UdpSocket, Packet),
  normalise_udp(Resp).

udp_receive(UdpSocket, Length, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  Resp = gen_udp:recv(UdpSocket, Length, T),
  normalise_udp(Resp).

udp_close(UdpSocket) ->
  gen_udp:close(UdpSocket),
  nil.

normalise_udp(ok) -> {ok, nil};
normalise_udp({ok, {Address, Port, _, Packet}}) ->
  {ok, {normalise_ip_address(Address), {port, Port}, Packet}};
normalise_udp({ok, {Address, Port, Packet}}) ->
  {ok, {normalise_ip_address(Address), {port, Port}, Packet}};
normalise_udp({ok, UdpSocket}) -> {ok, UdpSocket};
normalise_udp({error, closed} = E) -> E;
normalise_udp({error, timeout} = E) -> E;
normalise_udp({error, system_limit} = E) -> E;
normalise_udp({error, Posix}) -> {error, {posix, Posix}}.

normalise_ip_address({A, B, C, D}) ->
  {ipv4_address, A, B, C, D};
normalise_ip_address({A, B, C, D, E, F, G, H}) ->
  {ipv6_address, A, B, C, D, E, F, G, H}.

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.

ip_version_to_inet(ipv6) -> inet6;
ip_version_to_inet(ipv4) -> inet.
