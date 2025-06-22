open Core

let rec serialize = function
  | R.String data -> [%string "+%{data}\r\n"]
  | R.Error data -> [%string "-%{data}\r\n"]
  | R.Int data -> [%string ":%{data#Int}\r\n"]
  | R.Bulk_string data -> [%string "$%{String.length data#Int}\r\n%{data}\r\n"]
  | R.Array array ->
    let init = [%string "*%{List.length array#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) array
  | R.Null -> "_\r\n"
  | R.Bool data ->
    let data = if data then "t" else "f" in
    [%string "#%{data}\r\n"]
  | R.Double data -> [%string ",%{data#Float}\r\n"]
  | R.Big_int data -> [%string "(%{data#Z}\r\n"]
  | R.Bulk_error data -> [%string "!%{String.length data#Int}\r\n%{data}\r\n"]
  | R.Verbatim_string (enc, data) ->
    let concat = enc ^ ":" ^ data in
    [%string "=%{String.length concat#Int}\r\n%{concat}\r\n"]
  | R.Map map ->
    let init = [%string "%%{List.length map#Int}\r\n"] in
    List.fold ~init ~f:(fun acc (key, value) -> acc ^ serialize key ^ serialize value) map
  | R.Attribute attr ->
    let init = [%string "`%{List.length attr#Int}\r\n"] in
    List.fold
      ~init
      ~f:(fun acc (key, value) -> acc ^ serialize key ^ serialize value)
      attr
  | R.Set set ->
    let init = [%string "~%{List.length set#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) set
  | R.Push push ->
    let init = [%string ">%{List.length push#Int}\r\n"] in
    List.fold ~init ~f:(fun acc node -> acc ^ serialize node) push
;;
