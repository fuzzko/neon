-module(tcp_ffi).

-export([
  accept/2,
  close/1,
  listen/1,
  listen_ipv6/1,
  connect/3,
  send/2,
  recv_forever/2,
  recv/3,
  shutdown/1
]).

connect(Host, Port, IpVersion) ->
  Inet = case IpVersion of
    ipv4 -> inet;
    ipv6 -> inet6
  end,

  gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}, Inet]).

shutdown(Socket) ->
  Shut = gen_tcp:shutdown(Socket, read_write),
  normalise(Shut).

recv(Socket, Size, Timeout) ->
  Resp = gen_tcp:recv(Socket, Size, Timeout),
  normalise(Resp).

recv_forever(Socket, Size) ->
  Resp = gen_tcp:recv(Socket, Size, infinity),
  normalise(Resp).

send(Socket, Packet) ->
    Sent = gen_tcp:send(Socket, Packet),
    normalise(Sent).

listen(Port) ->
  Options = [
    binary,
    {ip, {127,0,0,1}},
    {packet, raw},
    {active, false},
    {reuseaddr, true}
  ],
  gen_tcp:listen(Port, Options).

listen_ipv6(Port) ->
  Options = [
    {ip, {0,0,0,0,0,0,0,1}},
    {packet, raw},
    {active, false},
    {reuseaddr, true},
    inet6
  ],
  gen_tcp:listen(Port, Options).

accept(Port, Timeout) ->
  gen_tcp:accept(Port, Timeout).

close(Port) ->
  case gen_tcp:close(Port) of
    ok -> {ok, nil};
    _ -> {error, nil}
  end.

%%% Normalise results %%%

normalise(ok) -> {ok, nil};
normalise({ok, T}) -> {ok, T};
normalise({error, {timeout, _}}) -> {error, timeout};
normalise({error, _} = E) -> E.
