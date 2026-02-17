-module(ssl_ffi).

-export([
  connect/3,
  send/2,
  recv_forever/2,
  recv/3,
  shutdown/1,
  close/1
]).

connect(Sock, Host, Verified) ->
  ssl:start(),

  Opts = case Verified of
    false -> [{verify, verify_none}];
    true -> [
      {verify, verify_peer},
      {cacerts, public_key:cacerts_get()},
      {server_name_idication, Host},
      {customize_hostname_check, [
        {match_fun, public_key:pkix_verify_hostname_match_fun(https)}
      ]
    }]
  end,

  ssl:connect(Sock, [binary, {packet, raw}, {active, false} | Opts]).

shutdown(Socket) ->
  Shut = ssl:shutdown(Socket, read_write),
  normalise(Shut).

close(Socket) ->
  with_rescue(fun() ->
    case ssl:close(Socket) of
      ok -> {ok, nil};
      {error, Reason} -> {error, Reason}
    end
  end).

recv(Socket, Size, Timeout) ->
  Resp = ssl:recv(Socket, Size, Timeout),
  normalise(Resp).

recv_forever(Socket, Size) ->
  Resp = ssl:recv(Socket, Size, infinity),
  normalise(Resp).

send(Socket, Packet) ->
    Sent = ssl:send(Socket, Packet),
    normalise(Sent).

%%% Normalise results %%%

normalise(ok) -> {ok, nil};
normalise({ok, T}) -> {ok, T};
normalise({error, {timeout, _}}) -> {error, timeout};
normalise({error, _} = E) -> E.

with_rescue(Fun) ->
  try Fun()
  catch error:badarg -> {error, nil}
  end.
