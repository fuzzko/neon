-module(neon_ffi).

-export([
  pkix_test_data/1
]).

%%% testing %%%

pkix_test_data(KeyType) ->
  KeyOpt = key_type_to_otp(KeyType),
  CertOpts = case KeyType of
    {ec, _} -> [{key, KeyOpt}, {digest, sha256}];
    _       -> [{key, KeyOpt}]
  end,
  ChainOpts = #{
    root => CertOpts,
    intermediates => [],
    peer => CertOpts
  },

  Conf = #{
    server_chain => ChainOpts,
    client_chain => ChainOpts
  },

  #{server_config := ServerConf, client_config := ClientConf} =
    public_key:pkix_test_data(Conf),

  {pkix_test_data, conf_to_cert_data(ServerConf), conf_to_cert_data(ClientConf)}.

conf_to_cert_data(Conf) ->
  Cert = proplists:get_value(cert, Conf),
  Key = erl_to_private_key(proplists:get_value(key, Conf)),
  CaCerts = proplists:get_value(cacerts, Conf),
  {cert_data, Cert, Key, CaCerts}.

erl_to_private_key({'RSAPrivateKey', Der}) -> {rsa_private_key, Der};
erl_to_private_key({'ECPrivateKey', Der}) -> {ec_private_key, Der}.

key_type_to_otp({rsa, Size}) -> {rsa, Size, 65537};
key_type_to_otp({ec, secp256r1}) -> {namedCurve, secp256r1};
key_type_to_otp({ec, secp384r1}) -> {namedCurve, secp384r1};
key_type_to_otp({ec, secp521r1}) -> {namedCurve, secp521r1}.
