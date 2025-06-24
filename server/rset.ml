open Core
open Resp
module S = Storage

let sadd = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | key :: values ->
    (match S.get ~key with
     | None ->
       let set = Hash_set.of_list (module String) values in
       S.set ~key ~data:(S.Set set);
       R.Int (Hash_set.length set)
     | Some (S.Set set) ->
       let before = Hash_set.length set in
       List.iter values ~f:(Hash_set.add set);
       R.Int (Hash_set.length set - before)
     | _ -> R.Error "WRONGTYPE expects to get a set")
;;

let scard = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    (match S.get ~key with
     | None -> R.Int 0
     | Some (S.Set set) -> R.Int (Hash_set.length set)
     | _ -> R.Error "WRONGTYPE expects to get a set")
  | _ -> R.Error "ERR not implemented"
;;

let smembers = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    (match S.get ~key with
     | None -> R.Set []
     | Some (S.Set set) ->
       let result =
         List.map (Hash_set.to_list set) ~f:(fun value -> R.Bulk_string value)
       in
       R.Set result
     | _ -> R.Error "WRONGTYPE expects to get a set")
  | _ -> R.Error "ERR not implemented"
;;

let srem = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | key :: values ->
    (match S.get ~key with
     | None -> R.Int 0
     | Some (S.Set set) ->
       let before = Hash_set.length set in
       List.iter values ~f:(Hash_set.remove set);
       R.Int (before - Hash_set.length set)
     | _ -> R.Error "WRONGTYPE expects to get a set")
;;

let sinter = function
  | [] -> R.Error "ERR not enough arguments"
  | keys ->
    let inter =
      List.fold
        keys
        ~init:(Hash_set.create (module String))
        ~f:(fun acc key ->
          match S.get ~key with
          | Some (S.Set set) -> Hash_set.inter acc set
          | _ -> acc)
    in
    let result =
      List.map (Hash_set.to_list inter) ~f:(fun value -> R.Bulk_string value)
    in
    R.Set result
;;

let sismember = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key; value ] ->
    (match S.get ~key with
     | None -> R.Int 0
     | Some (S.Set set) -> R.Int (Bool.to_int (Hash_set.mem set value))
     | _ -> R.Error "WRONGTYPE expects to get a set")
  | _ -> R.Error "ERR not implemented"
;;
