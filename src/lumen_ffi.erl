-module(lumen_ffi).

-export([
  inet_port/1,
  tcp_accept/2,
  tcp_close/1,
  tcp_listen/1,
  tcp_connect/3,
  tcp_send/2,
  tcp_recv/3,
  tcp_shutdown/1,
  ssl_connect/3,
  ssl_upgrade/3,
  ssl_send/2,
  ssl_recv/3,
  ssl_shutdown/1,
  ssl_close/1,
  udp_open/1,
  udp_connect/3,
  udp_send/2,
  udp_receive/3,
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
  normalise_tcp(Resp).

ip_version_to_inet(ipv6) -> inet6;
ip_version_to_inet(ipv4) -> inet.

tcp_shutdown(TcpSocket) ->
  Shut = gen_tcp:shutdown(TcpSocket, read_write),
  normalise_tcp(Shut).

tcp_recv(TcpSocket, Size, Timeout) ->
  RecvTimeout = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,

  Resp = gen_tcp:recv(TcpSocket, Size, RecvTimeout),
  normalise_tcp(Resp).

tcp_send(TcpSocket, Packet) ->
  Sent = gen_tcp:send(TcpSocket, Packet),
  normalise_tcp(Sent).

tcp_listen({listen_options, {port, Port}, IpAddress}) ->
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
  AcceptTimeout = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,

  Resp = gen_tcp:accept(TcpSocket, AcceptTimeout),
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

%%% ssl %%%

ssl_connect(Host, Port, Verified) ->
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

  Resp = ssl:connect(Host, Port, [binary, {packet, raw}, {active, false} | Opts]),
  normalise_ssl(Resp).

ssl_upgrade(TcpSocket, Host, Verified) ->
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
  normalise_ssl(Resp).

ssl_shutdown(SslSocket) ->
  Shut = ssl:shutdown(SslSocket, read_write),
  normalise_ssl(Shut).

ssl_close(SslSocket) ->
  Resp = ssl:close(SslSocket),
  normalise_ssl(Resp).

ssl_recv(SslSocket, Size, Timeout) ->
  RecvTimeout = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,

  Resp = ssl:recv(SslSocket, Size, RecvTimeout),
  normalise_ssl(Resp).

ssl_send(SslSocket, Packet) ->
  Sent = ssl:send(SslSocket, Packet),
  normalise_ssl(Sent).

normalise_ssl(ok) -> {ok, nil};
normalise_ssl({ok, SslSocket}) -> {ok, SslSocket};
normalise_ssl({error, closed}) -> {error, closed};
normalise_ssl({error, timeout}) -> {error, timeout};
normalise_ssl({error, {options, _}}) -> {error, invalid_options};
normalise_ssl({error, {tls_alert, {Alert, Description}}}) ->
  Desc = unicode:characters_to_binary(Description),
  {error, {tls_alert, {Alert, Desc}}};
normalise_ssl({error, Reason}) when is_atom(Reason) ->
  {error, {posix, Reason}};
normalise_ssl({error, Reason}) ->
  Formatted = ssl:format_error(Reason),
  Description = unicode:characters_to_binary(Formatted),
  {error, {other, Description}}.

%%% Udp %%%

udp_open(Port) ->
  normalise_udp(gen_udp:open(Port, [binary, {active, false}])).

udp_connect(UdpSocket, Address, Port) ->
  Resp = gen_udp:connect(UdpSocket, Address, Port),
  normalise_udp(Resp).

udp_send(UdpSocket, Packet) ->
  Resp = gen_udp:send(UdpSocket, Packet),
  normalise_udp(Resp).

udp_receive(UdpSocket, Length, Timeout) ->
  RecvTimeout = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,

  Resp = gen_udp:recv(UdpSocket, Length, RecvTimeout),
  normalise_udp(Resp).

udp_close(UdpSocket) ->
  gen_udp:close(UdpSocket),
  nil.

normalise_udp(ok) -> {ok, nil};
normalise_udp({ok, {Address, Port, _, Packet}}) ->
  {ok, {normalise_ip_address(Address), Port, Packet}};
normalise_udp({ok, {Address, Port, Packet}}) ->
  {ok, {normalise_ip_address(Address), Port, Packet}};
normalise_udp({ok, UdpSocket}) -> {ok, UdpSocket};
normalise_udp({error, closed} = E) -> E;
normalise_udp({error, timeout} = E) -> E;
normalise_udp({error, system_limit} = E) -> E;
normalise_udp({error, Posix}) -> {error, {posix, Posix}}.

normalise_ip_address({A, B, C, D}) ->
  {ipv4_address, A, B, C, D};
normalise_ip_address({A, B, C, D, E, F, G, H}) ->
  {ipv6_address, A, B, C, D, E, F, G, H}.
