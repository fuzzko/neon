-module(lumen_ffi).

-export([
  inet_port/1,
  tcp_accept/2,
  tcp_close/1,
  tcp_listen/1,
  tcp_connect/3,
  tcp_send/2,
  tcp_recv_forever/2,
  tcp_recv/3,
  tcp_shutdown/1,
  ssl_connect/3,
  ssl_send/2,
  ssl_recv_forever/2,
  ssl_recv/3,
  ssl_shutdown/1,
  ssl_close/1,
  udp_open/1,
  udp_connect/3,
  udp_send/2,
  udp_receive/3,
  udp_receive_forever/2,
  udp_close/1
]).

%%% inet %%%

inet_port(Socket) ->
  case inet:port(Socket) of
    {ok, Num} -> {ok, Num};
    {error, _} -> {error, nil}
  end.

%%% tcp %%%

tcp_connect(Host, Port, IpVersion) ->
  Inet = ip_version_to_inet(IpVersion),

  Resp = gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}, Inet]),
  normalise(Resp).

tcp_shutdown(TcpSocket) ->
  Shut = gen_tcp:shutdown(TcpSocket, read_write),
  normalise(Shut).

tcp_recv(TcpSocket, Size, Timeout) ->
  Resp = gen_tcp:recv(TcpSocket, Size, Timeout),
  normalise(Resp).

tcp_recv_forever(TcpSocket, Size) ->
  Resp = gen_tcp:recv(TcpSocket, Size, infinity),
  normalise(Resp).

tcp_send(TcpSocket, Packet) ->
    Sent = gen_tcp:send(TcpSocket, Packet),
    normalise(Sent).

tcp_listen({listen_options, Port, IpAddress}) ->
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
  normalise(Resp).

tcp_accept(TcpSocket, Timeout) ->
  Resp = gen_tcp:accept(TcpSocket, Timeout),
  normalise(Resp).

tcp_close(TcpSocket) ->
  case gen_tcp:close(TcpSocket) of
    ok -> {ok, nil};
    _ -> {error, nil}
  end.

ip_version_to_inet(ipv6) -> inet6;
ip_version_to_inet(ipv4) -> inet.

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.

%%% ssl %%%

ssl_connect(TcpSocket, Host, Verified) ->
  ssl:start(),

  Opts = case Verified of
    false -> [{verify, verify_none}];
    true -> [
      {verify, verify_peer},
      {cacerts, public_key:cacerts_get()},
      {server_name_indication, binary_to_list(Host)},
      {customize_hostname_check, [
        {match_fun, public_key:pkix_verify_hostname_match_fun(https)}
      ]
    }]
  end,

  Resp = ssl:connect(TcpSocket, [binary, {packet, raw}, {active, false} | Opts]),
  normalise(Resp).

ssl_shutdown(SslSocket) ->
  Shut = ssl:shutdown(SslSocket, read_write),
  normalise(Shut).

ssl_close(SslSocket) ->
  Resp = ssl:close(SslSocket),
  normalise(Resp).

ssl_recv(SslSocket, Size, Timeout) ->
  Resp = ssl:recv(SslSocket, Size, Timeout),
  normalise(Resp).

ssl_recv_forever(SslSocket, Size) ->
  Resp = ssl:recv(SslSocket, Size, infinity),
  normalise(Resp).

ssl_send(SslSocket, Packet) ->
  Sent = ssl:send(SslSocket, Packet),
  normalise(Sent).

%%% Udp %%%

udp_open(Port) ->
  normalise(gen_udp:open(Port, [binary, {active, false}])).

udp_connect(UdpSocket, Address, Port) ->
  Resp = gen_udp:connect(UdpSocket, Address, Port),
  normalise(Resp).

udp_send(UdpSocket, Packet) ->
  Resp = gen_udp:send(UdpSocket, Packet),
  normalise(Resp).

udp_receive(UdpSocket, Length, Timeout) ->
  Resp = gen_udp:recv(UdpSocket, Length, Timeout),
  normalise_udp_recv(Resp).

udp_receive_forever(UdpSocket, Length) ->
  Resp = gen_udp:recv(UdpSocket, Length),
  normalise_udp_recv(Resp).

udp_close(UdpSocket) ->
  Resp = gen_udp:close(UdpSocket),
  normalise(Resp).

%%% Normalise results %%%

normalise_udp_recv({ok, {Address, Port, _, Packet}}) ->
  {ok, {normalise_ip_address(Address), Port, Packet}};
normalise_udp_recv({ok, {Address, Port, Packet}}) ->
  {ok, {normalise_ip_address(Address), Port, Packet}};
normalise_udp_recv({error, timeout}) -> {error, timeout};
normalise_udp_recv({error, _} = E) -> E.

normalise_ip_address({A, B, C, D}) ->
  {ipv4_address, A, B, C, D};
normalise_ip_address({A, B, C, D, E, F, G, H}) ->
  {ipv6_address, A, B, C, D, E, F, G, H}.

normalise(ok) -> {ok, nil};
normalise({ok, T}) -> {ok, T};
normalise({error, {timeout, _}}) -> {error, timeout};
normalise({error, _} = E) -> E.
