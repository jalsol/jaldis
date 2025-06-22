open Core
open Caml_threads
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
let mutex = Mutex.create ()
let create_value ~data ~ttl = { data; ttl }

let set ~key ~value =
  Mutex.lock mutex;
  let data = create_value ~data:(String value) ~ttl:None in
  Hashtbl.set storage ~key ~data;
  Mutex.unlock mutex
;;

let get ~key =
  Mutex.lock mutex;
  let opt = Hashtbl.find storage key in
  Mutex.unlock mutex;
  opt >>= fun { data; ttl = _ } -> Some data
;;
