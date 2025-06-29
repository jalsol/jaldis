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
  | data -> failwithf "Bool: expects #t/#f, received #%s" data ()
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
  | len -> fail [%string "Bulk length must be non-negative or -1, got %{len#Int}"]
;;

let array elem =
  char '*' *> decimal
  <* crlf
  >>= function
  | -1 -> return R.Null
  | len when len >= 0 -> count len elem >>| fun elems -> R.Array elems
  | len -> fail [%string "Array length must be non-negative or -1, got %{len#Int}"]
;;

let collection ~prefix ~ctor elem =
  char prefix *> decimal
  <* crlf
  >>= function
  | len when len >= 0 -> count len elem >>| ctor
  | len -> fail [%string "Collection length must be non-negative, got %{len#Int}"]
;;

let pair_collection ~prefix ~ctor elem =
  char prefix *> decimal
  <* crlf
  >>= function
  | len when len >= 0 ->
    let pair = lift2 (fun k v -> k, v) elem elem in
    count len pair >>| ctor
  | len -> fail [%string "Pair collection length must be non-negative, got %{len#Int}"]
;;

let verbatim_string =
  char '=' *> decimal
  <* crlf
  >>= fun len ->
  if len < 0
  then fail [%string "Verbatim length must be non-negative, got %{len#Int}"]
  else
    take len
    <* crlf
    >>= fun data ->
    match String.lsplit2 ~on:':' data with
    | Some (fmt, content) -> return (R.Verbatim_string (fmt, content))
    | None -> fail "Verbatim string missing format separator ':'"
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
    ; array parse
    ; collection ~prefix:'~' ~ctor:(fun elems -> R.Set elems) parse
    ; collection ~prefix:'>' ~ctor:(fun elems -> R.Push elems) parse
    ; pair_collection ~prefix:'%' ~ctor:(fun pairs -> R.Map pairs) parse
    ; pair_collection ~prefix:'`' ~ctor:(fun pairs -> R.Attribute pairs) parse
    ]
;;
