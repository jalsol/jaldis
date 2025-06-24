open Core
open Option.Monad_infix

type data =
  | String of string
  | List of string Deque.t
  | Set of string Hash_set.t

let storage : (string, data) Hashtbl.t = Hashtbl.create (module String)
let expiry : (string, Time_ns.t) Hashtbl.t = Hashtbl.create (module String)

let is_expired ~key =
  match Hashtbl.find expiry key with
  | Some deadline when Time_ns.(now () > deadline) ->
    Hashtbl.remove storage key;
    Hashtbl.remove expiry key;
    true
  | _ -> false
;;

let set ~key ~data =
  let result = Hashtbl.set storage ~key ~data in
  Hashtbl.remove expiry key;
  result
;;

let get ~key = if is_expired ~key then None else Hashtbl.find storage key >>| Fn.id

let del ~key =
  Hashtbl.remove storage key;
  Hashtbl.remove expiry key
;;

let expire ~key ~duration =
  if Option.is_none (Hashtbl.find storage key)
  then false
  else (
    let span = Time_ns.Span.of_int_sec duration in
    Hashtbl.set expiry ~key ~data:Time_ns.(add (now ()) span);
    true)
;;

let length () = Hashtbl.length storage

let flushdb () =
  Hashtbl.clear storage;
  Hashtbl.clear expiry
;;

let keys () = Hashtbl.keys storage

let ttl_seconds deadline =
  let span = Time_ns.diff deadline (Time_ns.now ()) in
  let ns = Time_ns.Span.to_int63_ns span in
  if Int63.(ns <= zero)
  then 0
  else Int63.(ns / of_int 1_000_000_000) |> Int63.to_int_trunc
;;

let ttl ~key =
  match Hashtbl.find storage key, Hashtbl.find expiry key with
  | None, _ -> -2
  | Some _, None -> -1
  | Some _, Some deadline -> ttl_seconds deadline
;;

let collect_expired_keys ~quota ~now expiry_pairs =
  expiry_pairs
  |> List.filter ~f:(fun (_, ts) -> Time_ns.( <= ) ts now)
  |> (fun expired -> List.take expired quota)
  |> List.map ~f:fst
;;

let sweep_small_table ~quota ~now =
  let expired_keys = Hashtbl.to_alist expiry |> collect_expired_keys ~quota ~now in
  List.iter expired_keys ~f:(fun key -> del ~key);
  List.length expired_keys
;;

let sweep_large_table ~quota ~now =
  let removed = ref 0 in
  let attempts = ref 0 in
  let max_attempts = quota * 3 in
  while !removed < quota && !attempts < max_attempts && Hashtbl.length expiry > 0 do
    incr attempts;
    match Hashtbl.choose_randomly expiry with
    | None -> ()
    | Some (key, ts) when Time_ns.( <= ) ts now ->
      del ~key;
      incr removed
    | _ -> ()
  done;
  !removed
;;

let sweep_expired ?(quota = 20) () =
  let now = Time_ns.now () in
  let expiry_size = Hashtbl.length expiry in
  if expiry_size = 0
  then 0
  else if expiry_size <= quota * 5
  then sweep_small_table ~quota ~now
  else sweep_large_table ~quota ~now
;;
