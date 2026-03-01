-module(ssl_test_ffi).

-export([
  pkix_test_data/0
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
