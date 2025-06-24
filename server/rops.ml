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
