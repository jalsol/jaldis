(* Not supporting Attribute for now because it looks like a pain in the ass *)
type t =
  | String of string
  | Error of string
  | Int of int
  | Bulk_string of int * string
  | Array of int * t list
  | Null
  | Bool of bool
  | Double of float
  | Big_int of Z.t
  | Bulk_error of int * string
  | Verbatim_string of int * string * string
  | Map of int * (t * t) list
  | Set of int * t list
  | Push of int * t list

let rec validate = function
  | String _ | Error _ | Int _ | Null | Bool _ | Double _ | Big_int _ -> true
  | Bulk_string (len, data) | Bulk_error (len, data) -> String.length data = len
  | Verbatim_string (len, enc, data) ->
    String.length enc = 3 && String.length data = len - 4
  | Array (len, elems) | Set (len, elems) | Push (len, elems) ->
    List.length elems = len && List.for_all validate elems
  | Map (len, pairs) ->
    List.length pairs = len && List.for_all (fun (k, v) -> validate k && validate v) pairs
;;
