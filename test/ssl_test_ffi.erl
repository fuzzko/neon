-module(ssl_test_ffi).

-export([
  pkix_test_data/0,
  start_ssl_server/0,
  ssl_handshake/5
]).

pkix_test_data() ->
  Conf = #{
    server_chain => #{
      root => [{key, {rsa, 2048, 65537}}],
      intermediates => [],
      peer => [{key, {rsa, 2048, 65537}}]
    },
    client_chain => #{
      root => [{key, {rsa, 2048, 65537}}],
      intermediates => [],
      peer => [{key, {rsa, 2048, 65537}}]
    }
  },

  #{server_config := ServerConf} = public_key:pkix_test_data(Conf),

  Cert = proplists:get_value(cert, ServerConf),
  {'RSAPrivateKey', Key} = proplists:get_value(key, ServerConf),
  CaCerts = proplists:get_value(cacerts, ServerConf),

  {Cert, Key, CaCerts}.

start_ssl_server() ->
  application:ensure_all_started(ssl),
  application:ensure_all_started(public_key),

  nil.

%% Accepts an incoming TCP connection on the listener and upgrades
%% to SSL via server-side handshake. Returns {ok, SslSocket}.
ssl_handshake(TcpSocket, Cert, Key, CaCerts, Timeout) ->
  SslOpts = [
    {cert, Cert},
    {key, {'RSAPrivateKey', Key}},
    {cacerts, CaCerts},
    {verify, verify_none}
  ],

  Resp = ssl:handshake(TcpSocket, SslOpts, Timeout),
  normalise_ssl(Resp).

normalise_ssl(ok) -> {ok, nil};
normalise_ssl({ok, {_Address, Port}}) -> {ok, Port};
normalise_ssl({ok, SslSocket}) -> {ok, SslSocket};
normalise_ssl({ok, SslSocket, _Ext}) -> {ok, SslSocket};
normalise_ssl({error, closed}) -> {error, closed};
normalise_ssl({error, timeout}) -> {error, timeout};
normalise_ssl({error, {options, _}}) ->
  {error, invalid_options};
normalise_ssl({error, {tls_alert, {Alert, Description}}}) ->
  Desc = unicode:characters_to_binary(Description),
  {error, {tls_alert, {Alert, Desc}}};
normalise_ssl({error, Reason}) when is_atom(Reason) ->
  {error, {posix, Reason}};
normalise_ssl({error, Reason}) ->
  Formatted = ssl:format_error(Reason),
  Description = unicode:characters_to_binary(Formatted),
  {error, {ssl_error, Description}}.
