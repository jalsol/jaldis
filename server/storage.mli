type data =
  | String of string
  | List of string Core.Deque.t
  | Set of string Core.Hash_set.t

val set : key:string -> data:data -> unit
val get : key:string -> data option
val del : key:string -> unit
val expire : key:string -> duration:int -> bool
val ttl : key:string -> int
val length : unit -> int
val keys : unit -> string list
val flushdb : unit -> unit
val sweep_expired : ?quota:int -> unit -> int
