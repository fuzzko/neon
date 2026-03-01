-module(inet_ffi).

-export([
  port/1,
  parse_address/1,
  ntoa/1
]).

port(Socket) ->
  case inet:port(Socket) of
    {ok, Num} -> {ok, Num};
    {error, _} -> {error, nil}
  end.

parse_address(Address) ->
  case inet:parse_address(Address) of
    {ok, Tuple} -> {ok, to_ip_address(Tuple)};
    {error, einval} -> {error, einval}
  end.

ntoa({ipv4_address, A, B, C, D}) ->
  list_to_binary(inet:ntoa({A, B, C, D}));
ntoa({ipv6_address, A, B, C, D, E, F, G, H}) ->
  list_to_binary(inet:ntoa({A, B, C, D, E, F, G, H})).

to_ip_address({A, B, C, D}) ->
  {ipv4_address, A, B, C, D};
to_ip_address({A, B, C, D, E, F, G, H}) ->
  {ipv6_address, A, B, C, D, E, F, G, H}.
