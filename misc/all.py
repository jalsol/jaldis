#!/usr/bin/env python3
"""
End-to-end sanity test for the OCaml Redis-like server.

Usage:
  python integration_test.py            # assumes localhost:6969
  python integration_test.py 6380       # custom port

Requires:
  pip install redis
"""

import sys
import time
import redis
from contextlib import suppress

port = int(sys.argv[1]) if len(sys.argv) > 1 else 6969
r = redis.Redis(host="127.0.0.1", port=port, decode_responses=True, protocol=3)

def assert_eq(actual, expected, msg=""):
  if actual != expected:
    raise AssertionError(f"{msg}  expected={expected!r} got={actual!r}")


def main() -> None:
  r.flushdb()

  r.set("str1", "hello")
  assert_eq(r.get("str1"), "hello", "GET/SET failed")

  assert_eq(r.llen("list1"), 0)
  assert_eq(r.lpush("list1", "a", "b", "c"), 3) # size after op
  assert_eq(r.rpush("list1", "x", "y"), 5)
  assert_eq(r.lrange("list1", 0, -1), ["c", "b", "a", "x", "y"])
  assert_eq(r.lpop("list1"), "c")
  assert_eq(r.rpop("list1"), "y")
  assert_eq(r.lrange("list1", 0, 1), ["b", "a"])
  assert_eq(r.lrange("list1", -2, -1), ["a", "x"])
  assert_eq(r.llen("list1"), 3)

  assert_eq(r.sadd("set1", "a", "b", "c"), 3)
  assert_eq(r.sadd("set1", "b", "d"), 1) # only “d” was new
  assert_eq(r.scard("set1"), 4)
  assert_eq(r.smembers("set1"), {"a", "b", "c", "d"})
  assert_eq(r.sismember("set1", "c"), True)
  assert_eq(r.sismember("set1", "x"), False)
  assert_eq(r.srem("set1", "a", "x"), 1) # removed just “a”
  assert_eq(r.scard("set1"), 3)

  r.set("temp", "v") # 1-second TTL
  r.expire("temp", 1)
  t = r.ttl("temp")
  print(f"ttl={t}")
  assert t in (1, 0), f"TTL should be 0/1 immediately after set, got {t}"
  time.sleep(2) # wait for expiry + sweeper
  print("sleep done")
  assert_eq(r.ttl("temp"), -2, "Key should be gone (TTL -2)")
  assert_eq(r.get("temp"), None, "Expired key should be absent")

  print("✅  All tests passed")

if __name__ == "__main__":
  try:
    main()
  finally:
    with suppress(Exception):
      r.flushdb()
