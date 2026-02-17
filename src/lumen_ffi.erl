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
  ssl_close/1
]).

%%% inet %%%

inet_port({socket, Socket}) ->
  case inet:port(Socket) of
    {ok, Num} -> {ok, Num};
    {error, _} -> {error, nil}
  end.

%%% tcp %%%

tcp_connect(Host, Port, IpVersion) ->
  Inet = ip_version_to_inet(IpVersion),

  Resp = gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}, Inet]),
  normalise_socket(Resp).

tcp_shutdown({socket, TcpSocket}) ->
  Shut = gen_tcp:shutdown(TcpSocket, read_write),
  normalise(Shut).

tcp_recv({socket, Socket}, Size, Timeout) ->
  Resp = gen_tcp:recv(Socket, Size, Timeout),
  normalise(Resp).

tcp_recv_forever({socket, Socket}, Size) ->
  Resp = gen_tcp:recv(Socket, Size, infinity),
  normalise(Resp).

tcp_send({socket, TcpSocket}, Packet) ->
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
  normalise_socket(Resp).

tcp_accept({socket, TcpSocket}, Timeout) ->
  Resp = gen_tcp:accept(TcpSocket, Timeout),
  normalise_socket(Resp).

tcp_close({socket, TcpSocket}) ->
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

ssl_connect({socket, TcpSock}, Host, Verified) ->
  ssl:start(),

  Opts = case Verified of
    false -> [{verify, verify_none}];
    true -> [
      {verify, verify_peer},
      {cacerts, public_key:cacerts_get()},
      {server_name_idication, Host},
      {customize_hostname_check, [
        {match_fun, public_key:pkix_verify_hostname_match_fun(https)}
      ]
    }]
  end,

  Resp = ssl:connect(TcpSock, [binary, {packet, raw}, {active, false} | Opts]),
  normalise_socket(Resp).

ssl_shutdown({socket, SslSocket}) ->
  Shut = ssl:shutdown(SslSocket, read_write),
  normalise(Shut).

ssl_close({socket, SslSocket}) ->
  with_rescue(fun() ->
    Resp = ssl:close(SslSocket),
    normalise(Resp)
  end).

ssl_recv({socket, SslSocket}, Size, Timeout) ->
  Resp = ssl:recv(SslSocket, Size, Timeout),
  normalise(Resp).

ssl_recv_forever({socket, SslSocket}, Size) ->
  Resp = ssl:recv(SslSocket, Size, infinity),
  normalise(Resp).

ssl_send({socket, SslSocket}, Packet) ->
  Sent = ssl:send(SslSocket, Packet),
  normalise(Sent).

%%% Normalise results %%%

normalise_socket({ok, Socket}) -> {ok, {socket, Socket}};
normalise_socket({error, _} = E) -> E.

normalise(ok) -> {ok, nil};
normalise({ok, T}) -> {ok, T};
normalise({error, {timeout, _}}) -> {error, timeout};
normalise({error, _} = E) -> E.

with_rescue(Fun) ->
  try Fun()
  catch error:badarg -> {error, nil}
  end.
