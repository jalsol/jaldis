open Resp
module S = Storage

let set = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | [ key; value ] ->
    S.set ~key ~data:(S.String value);
    R.String "OK"
  | _ -> R.Error "ERR not implemented"
;;

let get = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    (match S.get ~key with
     | None -> R.Null
     | Some (S.String value) -> R.Bulk_string value
     | _ -> R.Error "WRONGTYPE expects to get a string")
  | _ -> R.Error "ERR not implemented"
;;
