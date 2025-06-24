open Core
open Option.Monad_infix

type data =
  | String of string
  | List of string Deque.t
  | Set of string Hash_set.t

let storage : (string, data) Hashtbl.t = Hashtbl.create (module String)
let expiry : (string, Time_ns.t) Hashtbl.t = Hashtbl.create (module String)

let expired ~key =
  match Hashtbl.find expiry key with
  | None -> false
  | Some expiry_time -> Time_ns.(now () < expiry_time)
;;

let set ~key ~data =
  let result = Hashtbl.set storage ~key ~data in
  Hashtbl.remove expiry key;
  result
;;

let get ~key = if expired ~key then None else Hashtbl.find storage key >>| Fn.id

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

let keys () = Hashtbl.keys storage |> List.filter ~f:(fun key -> expired ~key)

let ttl_seconds deadline =
  let span = Time_ns.diff deadline (Time_ns.now ()) in
  let ns = Time_ns.Span.to_int63_ns span in
  if Int63.(ns <= zero)
  then 0
  else Int63.(ns / of_int 1_000_000_000) |> Int63.to_int_trunc
;;

let ttl ~key =
  match Hashtbl.find storage key, Hashtbl.find expiry key with
  | None, _ -> `Key_not_exist
  | Some _, None -> `Key_no_expiry
  | Some _, Some deadline -> `Ttl (ttl_seconds deadline)
;;
