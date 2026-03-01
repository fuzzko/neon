-module(neon_test_ffi).

-export([log_error/0, log_default/0]).

log_error() ->
  logger:set_primary_config(level, error),
  nil.

log_default() ->
  logger:set_primary_config(level, notice),
  nil.
