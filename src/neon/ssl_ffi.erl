-module(ssl_ffi).

-export([
  start/0,
  port/1,
  connect/4,
  upgrade/4,
  send/2,
  recv/3,
  shutdown/1,
  close/1,
  listen/2,
  transport_accept/2,
  handshake/5
]).

start() ->
  Resp = ssl:start(),
  normalise(Resp).

port(SslSocket) ->
  Resp = ssl:sockname(SslSocket),
  normalise(Resp).

upgrade(TCPSocket, Host, Verify, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  TLSOpts = connect_opts(Host, Verify),
  Resp = ssl:connect(TCPSocket, TLSOpts, T),
  normalise(Resp).

connect(Host, Port, Verify, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  TLSOpts = connect_opts(Host, Verify),
  Resp = ssl:connect(Host, Port, TLSOpts, T),
  normalise(Resp).

connect_opts(Host, {verify, verify_none}) ->
  [
    binary,
    {packet, raw},
    {active, false},
    {verify, verify_none},
    {server_name_indication, Host}
  ];

connect_opts(Host, {verify, verify_peer}) ->
  [
    binary,
    {packet, raw},
    {active, false},
    {verify, verify_peer},
    {cacerts, public_key:cacerts_get()},
    {server_name_indication, Host},
    {customize_hostname_check, [
      {match_fun, public_key:pkix_verify_hostname_match_fun(https)}
    ]
  }].

shutdown(SslSocket) ->
  Shut = ssl:shutdown(SslSocket, read_write),
  normalise(Shut).

close(SslSocket) ->
  Resp = ssl:close(SslSocket),
  normalise(Resp).

recv(SslSocket, Size, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  Resp = ssl:recv(SslSocket, Size, T),
  normalise(Resp).

send(SslSocket, Packet) ->
  Sent = ssl:send(SslSocket, Packet),
  normalise(Sent).

listen(Port, IpAddress) ->
  {Inet, Address} = ip_address_and_version(IpAddress),

  Options = [
    binary,
    {ip, Address},
    {packet, raw},
    {active, false},
    {reuseaddr, true},
    Inet
  ],
  Resp = ssl:listen(Port, Options),
  normalise(Resp).

transport_accept(ListenSocket, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  Resp = ssl:transport_accept(ListenSocket, T),
  normalise(Resp).

handshake(Socket, Cert, Key, MaybeCaCerts, Timeout) ->
  T = case Timeout of
    infinity -> infinity;
    {timeout, Int} -> Int
  end,
  ErlKey = private_key_to_erl(Key),

  BaseOpts = [
    {cert, Cert},
    {key, ErlKey},
    {verify, verify_none}
  ],

  Opts = case MaybeCaCerts of
    none -> BaseOpts;
    {some, CaCerts} -> [{cacerts, CaCerts} | BaseOpts]
  end,

  Resp = ssl:handshake(Socket, Opts, T),
  normalise(Resp).

private_key_to_erl({rsa_private_key, Der}) -> {'RSAPrivateKey', Der};
private_key_to_erl({ec_private_key, Der}) -> {'ECPrivateKey', Der}.

normalise(ok) -> {ok, nil};
normalise({ok, {_Address, Port}}) -> {ok, {port, Port}};
normalise({ok, SslSocket}) -> {ok, SslSocket};
normalise({ok, SslSocket, _Ext}) -> {ok, SslSocket};
normalise({error, closed}) -> {error, closed};
normalise({error, timeout}) -> {error, timeout};
normalise({error, {tls_alert, {Alert, Description}}}) ->
  Desc = unicode:characters_to_binary(Description),
  {error, {tls_alert, {Alert, Desc}}};
normalise({error, Reason}) when is_atom(Reason) ->
  {error, {posix, Reason}};
normalise({error, Reason}) ->
  Formatted = ssl:format_error(Reason),
  Description = unicode:characters_to_binary(Formatted),
  {error, {error, Description}}.

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.
