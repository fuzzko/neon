-module(neon_test_ffi).

-export([suppress_logger/0, default_logger/0]).

suppress_logger() ->
  logger:set_primary_config(level, emergency),
  nil.

default_logger() ->
  logger:set_primary_config(level, notice),
  nil.
