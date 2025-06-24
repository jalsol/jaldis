open Core
open Resp

let hello =
  R.Map
    [ R.String "server", R.String "jaldis"
    ; R.String "version", R.String "0.0.1"
    ; R.String "proto", R.Int 3
    ; R.String "hotel", R.String "trivago"
    ]
;;

let ping = function
  | [] -> R.String "PONG"
  | [ msg ] -> R.Bulk_string msg
  | _ -> R.Error "ERR wrong argument"
;;

let flushdb = function
  | [] ->
    Storage.flushdb ();
    R.String "OK"
  | _ -> R.Error "ERR not implemented"
;;

let del = function
  | [] -> R.Error "ERR not enough arguments"
  | keys ->
    let before = Storage.length () in
    List.iter keys ~f:(fun key -> Storage.del ~key);
    R.Int (before - Storage.length ())
;;

let keys () =
  let keys = List.map (Storage.keys ()) ~f:(fun key -> R.Bulk_string key) in
  R.Array keys
;;

let expire = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | [ key; duration ] ->
    (match Int.of_string_opt duration with
     | None -> R.Error "ERR duration has to be int"
     | Some duration -> R.Int (Bool.to_int (Storage.expire ~key ~duration)))
  | _ -> R.Error "ERR Not implemented"
;;

let ttl = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    (match Storage.ttl ~key with
     | `Key_not_exist -> R.Int (-2)
     | `Key_no_expire -> R.Int (-1)
     | `Ttl duration -> R.Int duration
     | _ -> failwith "Not happening")
  | _ -> R.Error "ERR Not implemented"
;;
