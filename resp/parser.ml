open Core
open Angstrom

let crlf = string "\r\n"

let decimal =
  lift2
    (fun sign digits -> Int.of_string (sign ^ digits))
    (option "" (string "-"))
    (take_while1 Char.is_digit)
;;

let bool_of_string = function
  | "t" -> true
  | "f" -> false
  | _ as data -> failwithf "Bool: expects #t/#f, received #%s" data ()
;;

let simple ~prefix ~ctor ~cast =
  char prefix *> take_till (Char.equal '\r') <* crlf >>| cast >>| ctor
;;

let bulk ~prefix ~ctor =
  char prefix *> decimal
  <* crlf
  >>= function
  | -1 -> return R.Null
  | len when len >= 0 -> take len <* crlf >>| ctor
  | _ -> fail "Bulk length has to be non-negative or null"
;;

let verbatim_string =
  char '=' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail "Verbatim length has to be non-negative"
  else
    take len
    <* crlf
    >>= fun data ->
    match String.lsplit2 ~on:':' data with
    | Some (fmt, data) -> return (R.Verbatim_string (fmt, data))
    | None -> fail "Verbatim string missing ':'"
;;

let array_of elem =
  char '*' *> decimal
  <* crlf
  >>= function
  | -1 -> return R.Null
  | len when len >= 0 -> count len elem >>| fun elems -> R.Array elems
  | _ -> fail "Array length has to be non-negative or null"
;;

let set_of elem =
  char '~' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail "Set length has to be non-negative"
  else count len elem >>| fun elems -> R.Set elems
;;

let push_of elem =
  char '>' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail "Push length has to be non-negative"
  else count len elem >>| fun elems -> R.Push elems
;;

let map_of elem =
  char '%' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail "Map length has to be non-negative"
  else (
    let pair = lift2 (fun k v -> k, v) elem elem in
    count len pair >>| fun elems -> R.Map elems)
;;

let attribute_of elem =
  char '`' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail "Attribute length has to be non-negative"
  else (
    let pair = lift2 (fun k v -> k, v) elem elem in
    count len pair >>| fun elems -> R.Attribute elems)
;;

let parse =
  fix
  @@ fun parse ->
  choice
    [ simple ~prefix:'+' ~ctor:(fun data -> R.String data) ~cast:Fn.id
    ; simple ~prefix:'-' ~ctor:(fun data -> R.Error data) ~cast:Fn.id
    ; simple ~prefix:':' ~ctor:(fun data -> R.Int data) ~cast:Int.of_string
    ; simple ~prefix:'_' ~ctor:(fun _ -> R.Null) ~cast:Fn.id
    ; simple ~prefix:'#' ~ctor:(fun data -> R.Bool data) ~cast:bool_of_string
    ; simple ~prefix:',' ~ctor:(fun data -> R.Double data) ~cast:Float.of_string
    ; simple ~prefix:'(' ~ctor:(fun data -> R.Big_int data) ~cast:Z.of_string
    ; bulk ~prefix:'$' ~ctor:(fun data -> R.Bulk_string data)
    ; bulk ~prefix:'!' ~ctor:(fun data -> R.Bulk_error data)
    ; verbatim_string
    ; array_of parse
    ; set_of parse
    ; push_of parse
    ; map_of parse
    ; attribute_of parse
    ]
;;
