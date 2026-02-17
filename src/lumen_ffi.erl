-module(lumen_ffi).

-export([
  port/1
]).

port(Socket) ->
  case inet:port(Socket) of
    {ok, Num} -> {ok, Num};
    {error, _} -> {error, nil}
  end.
