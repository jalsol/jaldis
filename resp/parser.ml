open Core
open Core.Or_error.Monad_infix

type t =
  { input : string
  ; pos : int
  ; ch : char option
  }

let init input =
  if String.length input = 0
  then { input; pos = 0; ch = None }
  else { input; pos = 0; ch = Some (String.get input 0) }
;;

let scan_ended ?(offset = 0) parser = parser.pos + offset >= String.length parser.input

let advance_by parser ~n =
  let pos = parser.pos + n in
  let ch =
    if scan_ended parser ~offset:n then None else Some (String.get parser.input pos)
  in
  { parser with pos; ch }
;;

let advance = advance_by ~n:1

let parse_simple parser =
  Or_error.try_with (fun () ->
    String.substr_index_exn ~pos:parser.pos ~pattern:"\r\n" parser.input)
  >>= fun i ->
  let len = i - parser.pos in
  let next_parser = advance_by parser ~n:(len + 2) in
  Ok (next_parser, String.sub ~pos:parser.pos ~len parser.input)
;;

let parse_string parser =
  parse_simple parser >>| fun (parser, data) -> parser, Ast.String data
;;

let parse_error parser =
  parse_simple parser >>| fun (parser, data) -> parser, Ast.Error data
;;

let parse_int parser =
  parse_simple parser
  >>= fun (parser, data) ->
  Or_error.try_with (fun () -> Int.of_string data) >>| fun num -> parser, Ast.Int num
;;

let parse_double parser =
  parse_simple parser
  >>= fun (parser, data) ->
  Or_error.try_with (fun () -> Float.of_string data) >>| fun num -> parser, Ast.Double num
;;

let parse_big_int parser =
  parse_simple parser
  >>= fun (parser, data) ->
  Or_error.try_with (fun () -> Z.of_string data) >>| fun num -> parser, Ast.Big_int num
;;

let parse_null parser = parse_simple parser >>| fun (parser, _) -> parser, Ast.Null

let parse_bool parser =
  parse_simple parser
  >>= fun (parser, data) ->
  (match data with
   | "t" -> Ok true
   | "f" -> Ok false
   | _ -> Or_error.errorf "Bool: Expects #t/#f, found #%s" data)
  >>| fun data -> parser, Ast.Bool data
;;

let parse_aggregate parser =
  Or_error.try_with (fun () ->
    String.substr_index_exn ~pos:parser.pos ~pattern:"\r\n" parser.input)
  >>= fun i ->
  let len = i - parser.pos in
  Or_error.try_with (fun () ->
    Int.of_string (String.sub ~pos:parser.pos ~len parser.input))
  >>| fun num ->
  let next_parser = advance_by parser ~n:(len + 2) in
  next_parser, num
;;

let parse_bulk_string parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  if len = -1
  then Ok (parser, Ast.Null)
  else
    Or_error.try_with (fun () ->
      String.substr_index_exn ~pos:parser.pos ~pattern:"\r\n" parser.input)
    >>= fun i ->
    if len = -1
    then Ok (parser, Ast.Null)
    else if i - parser.pos <> len
    then
      Or_error.errorf
        "Bulk String: Expects length %d, received length %d"
        len
        (i - parser.pos)
    else (
      let next_parser = advance_by parser ~n:(len + 2) in
      Ok (next_parser, Ast.Bulk_string (String.sub ~pos:parser.pos ~len parser.input)))
;;

let parse_bulk_error parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  Or_error.try_with (fun () ->
    String.substr_index_exn ~pos:parser.pos ~pattern:"\r\n" parser.input)
  >>= fun i ->
  if i - parser.pos <> len
  then
    Or_error.errorf
      "Bulk Error: Expects length %d, received length %d"
      len
      (i - parser.pos)
  else (
    let next_parser = advance_by parser ~n:(len + 2) in
    Ok (next_parser, Ast.Bulk_error (String.sub ~pos:parser.pos ~len parser.input)))
;;

let parse_verbatim_string parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  Or_error.try_with (fun () ->
    String.substr_index_exn ~pos:parser.pos ~pattern:"\r\n" parser.input)
  >>= fun i ->
  if i - parser.pos <> len
  then
    Or_error.errorf
      "Verbatim String: Expects length %d, received length %d"
      len
      (i - parser.pos)
  else (
    let data = String.sub ~pos:parser.pos ~len parser.input in
    Or_error.try_with (fun () -> String.lsplit2_exn ~on:':' data)
    >>= fun (enc, data) ->
    if String.length enc <> 3
    then Or_error.errorf "Verbatim String: Received enc length %d" (String.length enc)
    else (
      let next_parser = advance_by parser ~n:(len + 2) in
      Ok (next_parser, Ast.Verbatim_string (enc, data))))
;;

let rec parse_element parser n =
  if n = 0
  then Ok (parser, [])
  else
    parse_next parser
    >>= fun (parser, elem) ->
    parse_element parser (n - 1) >>| fun (parser, rest) -> parser, elem :: rest

and parse_key_value parser n =
  if n = 0
  then Ok (parser, [])
  else
    parse_next parser
    >>= fun (parser, key) ->
    parse_next parser
    >>= fun (parser, value) ->
    parse_key_value parser (n - 1) >>| fun (parser, rest) -> parser, (key, value) :: rest

and parse_array parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  if len = -1
  then Ok (parser, Ast.Null)
  else parse_element parser len >>| fun (parser, arr) -> parser, Ast.Array arr

and parse_set parser =
  (* TODO: set condition? *)
  parse_aggregate parser
  >>= fun (parser, len) ->
  parse_element parser len >>| fun (parser, set) -> parser, Ast.Set set

and parse_push parser =
  (* TODO: push condition? *)
  parse_aggregate parser
  >>= fun (parser, len) ->
  parse_element parser len >>| fun (parser, push) -> parser, Ast.Push push

and parse_map parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  parse_key_value parser len >>| fun (parser, map) -> parser, Ast.Map map

and parse_attribute parser =
  parse_aggregate parser
  >>= fun (parser, len) ->
  parse_key_value parser len
  >>| fun (parser, attribute) -> parser, Ast.Attribute attribute

and parse_next parser =
  match parser.ch with
  | None -> Or_error.error_string "eof"
  | Some ch ->
    let parse_func = function
      | '+' -> parse_string
      | '-' -> parse_error
      | ':' -> parse_int
      | '$' -> parse_bulk_string
      | '*' -> parse_array
      | '_' -> parse_null
      | '#' -> parse_bool
      | ',' -> parse_double
      | '(' -> parse_big_int
      | '!' -> parse_bulk_error
      | '=' -> parse_verbatim_string
      | '%' -> parse_map
      | '`' -> parse_attribute
      | '~' -> parse_set
      | '>' -> parse_push
      | _ -> fun _ -> Or_error.errorf "Found invalid character %c" ch
    in
    parser |> advance |> parse_func ch
;;
