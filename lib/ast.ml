type t =
  | String of string
  | Error of string (* TODO: should I use the actual error type? *)
  | Int of int
  | Bulk_string of int * string
  | Array of int * t list
  | Null
  | Bool of bool
  | Double of float
  | Big_int of string (* TODO: implement Big Int/use Zarith? *)
  | Bulk_error of int * string (* TODO: should I use the actual error type? *)
  | Verbatim_string of int * string * string
  | Map of int * (t * t) list
  (* Not supporting Attribute because it looks like a pain in the ass *)
  | Set of int * t list
  | Push of int * t list
