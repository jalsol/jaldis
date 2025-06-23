#!/usr/bin/env python3
"""
Smoke-test for essential Redis/RESP commands:

  SET / GET
  LPUSH / RPUSH / LLEN
  LRANGE
  LPOP / RPOP (incl. COUNT form)
"""
import sys
import random
import string
from contextlib import suppress

import redis

HOST = "127.0.0.1"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 6969
r = redis.Redis(host=HOST, port=PORT, decode_responses=True)

def rand_key(prefix: str) -> str:
  return prefix + "_" + "".join(random.choices(string.ascii_lowercase, k=6))

def expect_equal(actual, expected, msg):
  assert actual == expected, f"{msg}: expected {expected!r} got {actual!r}"

def main() -> None:
  r.flushdb()

  k1 = rand_key("str")
  expect_equal(r.set(k1, "hello"), True, "SET should reply OK/True")
  expect_equal(r.get(k1), "hello", "GET round-trip")

  k2 = rand_key("list")
  expect_equal(r.llen(k2), 0, "empty list length")

  expect_equal(r.lpush(k2, "a", "b", "c"), 3, "LPUSH 3 elements")
  expect_equal(r.rpush(k2, "x", "y"), 5, "RPUSH 2 elements -> len 5")

  expect_equal(r.llen(k2), 5, "LLEN after pushes")


  expect_equal(r.lrange(k2, 0, -1), ["c", "b", "a", "x", "y"], "LRANGE full")

  expect_equal(r.lpop(k2), "c", "LPOP returns head")
  expect_equal(r.rpop(k2), "y", "RPOP returns tail")

  expect_equal(r.lrange(k2, 0, 1), ["b", "a"], "LRANGE first two")
  expect_equal(r.lrange(k2, -2, -1), ["a", "x"], "LRANGE last two")

  expect_equal(r.llen(k2), 3, "LLEN after single pops")

  popped = r.lpop(k2, 3)
  expect_equal(popped, ["b", "a", "x"], "multi-LPOP result")
  expect_equal(r.llen(k2), 0, "list empty now")

  expect_equal(r.lrange(k2, 0, -1), [], "LRANGE on empty list")

  print("✓ all basic tests passed")

if __name__ == "__main__":
  try:
    main()
  finally:
    with suppress(Exception):
      r.flushdb()
