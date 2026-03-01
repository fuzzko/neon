-module(neon_ffi).

-export([
  pkix_test_data/1,
  udp_open/3,
  udp_connect/3,
  udp_send/2,
  udp_receive/3,
  udp_close/1
]).

ip_address_and_version({ipv4_address, A, B, C, D}) ->
  {inet, {A, B, C, D}};
ip_address_and_version({ipv6_address, A, B, C, D, E, F, G, H}) ->
  {inet6, {A, B, C, D, E, F, G, H}}.

ip_version_to_inet(ipv6) -> inet6;
ip_version_to_inet(ipv4) -> inet.

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

%%% Udp %%%

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
  T = normalise_timeout(Timeout),
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

normalise_timeout(infinity) -> infinity;
normalise_timeout({timeout, Int}) -> Int.
