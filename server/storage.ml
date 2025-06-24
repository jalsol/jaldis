open Core
open Option.Monad_infix

type data =
  | String of string
  | List of string Deque.t
  | Set of string Hash_set.t

type value =
  { data : data
  ; ttl : int option
  }

let storage : (string, value) Hashtbl.t = Hashtbl.create (module String)
let create_value ~data ~ttl = { data; ttl }

let set ~key ~data =
  let data = create_value ~data ~ttl:None in
  Hashtbl.set storage ~key ~data
;;

let get ~key =
  let opt = Hashtbl.find storage key in
  opt >>= fun { data; ttl = _ } -> Some data
;;

let flushdb () = Hashtbl.clear storage
