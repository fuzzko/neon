-module(inet_ffi).

-export([
  inet_port/1,
  inet_parse_address/1,
  inet_ntoa/1
]).

inet_port(Socket) ->
  case inet:port(Socket) of
    {ok, Num} -> {ok, Num};
    {error, _} -> {error, nil}
  end.

inet_parse_address(Address) ->
  case inet:parse_address(Address) of
    {ok, Tuple} -> {ok, normalise_ip_address(Tuple)};
    {error, einval} -> {error, einval}
  end.

inet_ntoa({ipv4_address, A, B, C, D}) ->
  list_to_binary(inet:ntoa({A, B, C, D}));
inet_ntoa({ipv6_address, A, B, C, D, E, F, G, H}) ->
  list_to_binary(inet:ntoa({A, B, C, D, E, F, G, H})).

normalise_ip_address({A, B, C, D}) ->
  {ipv4_address, A, B, C, D};
normalise_ip_address({A, B, C, D, E, F, G, H}) ->
  {ipv6_address, A, B, C, D, E, F, G, H}.
