open Core

type t =
  | String of string
  | Error of string
  | Int of int
  | Bulk_string of string
  | Array of t list
  | Null
  | Bool of bool
  | Double of float
  | Big_int of Big_int.t
  | Bulk_error of string
  | Verbatim_string of string * string
  | Map of (t * t) list
  | Attribute of (t * t) list
  | Set of t list
  | Push of t list
[@@deriving sexp_of]
