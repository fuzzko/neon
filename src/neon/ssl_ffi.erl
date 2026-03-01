-module(ssl_ffi).

-export([
  ssl_start/0,
  ssl_port/1,
  ssl_connect/4,
  ssl_upgrade/4,
  ssl_send/2,
  ssl_recv/3,
  ssl_shutdown/1,
  ssl_close/1,
  ssl_listen/2,
  ssl_transport_accept/2,
  ssl_handshake/5
]).

ssl_start() ->
  Resp = ssl:start(),
  normalise_ssl(Resp).

ssl_port(SslSocket) ->
  Resp = ssl:sockname(SslSocket),
  normalise_ssl(Resp).

ssl_upgrade(TCPSocket, Host, Verify, Timeout) ->
  T = normalise_timeout(Timeout),
  TLSOpts = ssl_connect_opts(Host, Verify),
  Resp = ssl:connect(TCPSocket, TLSOpts, T),
  normalise_ssl(Resp).

ssl_connect(Host, Port, Verify, Timeout) ->
  T = normalise_timeout(Timeout),
  TLSOpts = ssl_connect_opts(Host, Verify),
  Resp = ssl:connect(Host, Port, TLSOpts, T),
  normalise_ssl(Resp).

ssl_connect_opts(Host, {verify, verify_none}) ->
  [
    binary,
    {packet, raw},
    {active, false},
    {verify, verify_none},
    {server_name_indication, Host}
  ];

ssl_connect_opts(Host, {verify, verify_peer}) ->
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

ssl_shutdown(SslSocket) ->
  Shut = ssl:shutdown(SslSocket, read_write),
  normalise_ssl(Shut).

ssl_close(SslSocket) ->
  Resp = ssl:close(SslSocket),
  normalise_ssl(Resp).

ssl_recv(SslSocket, Size, Timeout) ->
  T = normalise_timeout(Timeout),
  Resp = ssl:recv(SslSocket, Size, T),
  normalise_ssl(Resp).

ssl_send(SslSocket, Packet) ->
  Sent = ssl:send(SslSocket, Packet),
  normalise_ssl(Sent).

ssl_listen(Port, IpAddress) ->
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
  normalise_ssl(Resp).

ssl_transport_accept(ListenSocket, Timeout) ->
  T = normalise_timeout(Timeout),
  Resp = ssl:transport_accept(ListenSocket, T),
  normalise_ssl(Resp).

ssl_handshake(Socket, Cert, Key, MaybeCaCerts, Timeout) ->
  T = normalise_timeout(Timeout),
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
  normalise_ssl(Resp).

private_key_to_erl({rsa_private_key, Der}) -> {'RSAPrivateKey', Der};
private_key_to_erl({ec_private_key, Der}) -> {'ECPrivateKey', Der}.

normalise_ssl(ok) -> {ok, nil};
normalise_ssl({ok, {_Address, Port}}) -> {ok, {port, Port}};
normalise_ssl({ok, SslSocket}) -> {ok, SslSocket};
normalise_ssl({ok, SslSocket, _Ext}) -> {ok, SslSocket};
normalise_ssl({error, closed}) -> {error, closed};
normalise_ssl({error, timeout}) -> {error, timeout};
normalise_ssl({error, {tls_alert, {Alert, Description}}}) ->
  Desc = unicode:characters_to_binary(Description),
  {error, {tls_alert, {Alert, Desc}}};
normalise_ssl({error, Reason}) when is_atom(Reason) ->
  {error, {posix, Reason}};
normalise_ssl({error, Reason}) ->
  Formatted = ssl:format_error(Reason),
  Description = unicode:characters_to_binary(Formatted),
  {error, {ssl_error, Description}}.

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.

normalise_timeout(infinity) -> infinity;
normalise_timeout({timeout, Int}) -> Int.
