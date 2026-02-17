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

  case ssl:handshake(TcpSocket, SslOpts, Timeout) of
    {ok, SslSocket} -> {ok, SslSocket};
    {ok, SslSocket, _Ext} -> {ok, SslSocket};
    {error, Reason} -> {error, Reason}
  end.
