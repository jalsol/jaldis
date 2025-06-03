open Core

let rec serialize = function
  | Ast.String data -> [%string "+%{data}\r\n"]
  | Ast.Error data -> [%string "-%{data}\r\n"]
  | Ast.Int data -> [%string ":%{data#Int}\r\n"]
  | Ast.Bulk_string data -> [%string "$%{String.length data#Int}\r\n%{data}\r\n"]
  | Ast.Array array ->
    let init = [%string "*%{List.length array#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) array
  | Ast.Null -> "_\r\n"
  | Ast.Bool data ->
    let data = if data then "t" else "f" in
    [%string "#%{data}\r\n"]
  | Ast.Double data -> [%string ",%{data#Float}\r\n"]
  | Ast.Big_int data -> [%string "(%{data#Z}\r\n"]
  | Ast.Bulk_error data -> [%string "!%{String.length data#Int}\r\n%{data}\r\n"]
  | Ast.Verbatim_string (enc, data) ->
    let concat = enc ^ ":" ^ data in
    [%string "=%{String.length concat#Int}\r\n%{concat}\r\n"]
  | Ast.Map map ->
    let init = [%string "%%{List.length map#Int}\r\n"] in
    List.fold ~init ~f:(fun acc (key, value) -> acc ^ serialize key ^ serialize value) map
  | Ast.Attribute attr ->
    let init = [%string "`%{List.length attr#Int}\r\n"] in
    List.fold
      ~init
      ~f:(fun acc (key, value) -> acc ^ serialize key ^ serialize value)
      attr
  | Ast.Set set ->
    let init = [%string "~%{List.length set#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) set
  | Ast.Push push ->
    let init = [%string ">%{List.length push#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) push
;;
