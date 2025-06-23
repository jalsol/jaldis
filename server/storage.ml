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

let with_lock ~f =
  Mutex.lock mutex;
  let result = f () in
  Mutex.unlock mutex;
  result
;;

let set_nolock ~key ~data =
  let data = create_value ~data ~ttl:None in
  Hashtbl.set storage ~key ~data
;;

let set ~key ~data =
  Mutex.lock mutex;
  set_nolock ~key ~data;
  Mutex.unlock mutex
;;

let get_nolock ~key =
  let opt = Hashtbl.find storage key in
  opt >>= fun { data; ttl = _ } -> Some data
;;

let get ~key =
  Mutex.lock mutex;
  let result = get_nolock ~key in
  Mutex.unlock mutex;
  result
;;

let flushdb () =
  Mutex.lock mutex;
  Hashtbl.clear storage;
  Mutex.unlock mutex
;;
