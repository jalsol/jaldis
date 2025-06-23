open Core
open Resp
module S = Storage

let llen = function
  | [] -> R.Error "ERR not enough arguments"
  | [ key ] ->
    (match S.get ~key with
     | None -> R.Int 0
     | Some (S.List list) -> R.Int (Deque.length list)
     | Some _ -> R.Error "WRONGTYPE expects to get a list")
  | _ -> R.Error "ERR not implemented"
;;

let push ~back_or_front = function
  | [] | [ _ ] -> R.Error "ERR not enough arguments"
  | key :: values ->
    S.with_lock ~f:(fun () ->
      match S.get_nolock ~key with
      | None ->
        let list = Deque.create () in
        List.iter values ~f:(Deque.enqueue list back_or_front);
        S.set_nolock ~key ~data:(S.List list);
        R.Int (Deque.length list)
      | Some (S.List list) ->
        List.iter values ~f:(Deque.enqueue list back_or_front);
        R.Int (Deque.length list)
      | Some _ -> R.Error "WRONGTYPE expects to get a list")
;;

let lpush = push ~back_or_front:`front
let rpush = push ~back_or_front:`back

type pop_count =
  | Default_one
  | Explicit of int

let pop_parse_count = function
  | [] -> Ok Default_one
  | [ s ] ->
    (match Int.of_string_opt s with
     | Some n when n > 0 -> Ok (Explicit n)
     | _ -> Error "ERR expects positive count")
  | _ -> Error "ERR too many arguments"
;;

let pop ~back_or_front = function
  | [] -> R.Error "ERR not enough arguments"
  | key :: rest ->
    (match pop_parse_count rest with
     | Error msg -> R.Error msg
     | Ok count_desc ->
       S.with_lock ~f:(fun () ->
         match S.get_nolock ~key with
         | None -> R.Null
         | Some (S.List list) ->
           let count =
             match count_desc with
             | Default_one -> 1
             | Explicit n -> n
           in
           let popped = ref [] in
           for _ = 1 to count do
             match Deque.dequeue list back_or_front with
             | Some value -> popped := R.Bulk_string value :: !popped
             | None -> ()
           done;
           let popped = List.rev !popped in
           (match count_desc, popped with
            | Default_one, [] -> R.Null
            | Default_one, [ value ] -> value
            | Default_one, _ -> failwith "Internal error"
            | Explicit _, values -> R.Array values)
         | Some _ -> R.Error "WRONGTYPE expects to get a list"))
;;

let lpop = pop ~back_or_front:`front
let rpop = pop ~back_or_front:`back

let lrange = function
  | [] | [ _ ] | [ _; _ ] -> R.Error "ERR not enough arguments"
  | [ key; start; stop ] ->
    (match Option.both (Int.of_string_opt start) (Int.of_string_opt stop) with
     | None -> R.Error "ERR Expects 2 integers as bounds"
     | Some (start, stop) ->
       S.with_lock ~f:(fun () ->
         match S.get_nolock ~key with
         | None -> R.Array []
         | Some (S.List list) ->
           let n = Deque.length list in
           let start = if start < 0 then n + start else start in
           let stop = if stop < 0 then n + stop else stop in
           let acc = ref [] in
           let i = ref 0 in
           Deque.iter list ~f:(fun elem ->
             if start <= !i && !i <= stop then acc := R.Bulk_string elem :: !acc;
             incr i);
           R.Array (List.rev !acc)
         | Some _ -> R.Error "WRONGTYPE expects to get a list"))
  | _ -> R.Error "ERR not implemented"
;;
