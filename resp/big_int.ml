open Sexplib

type t = Z.t

let sexp_of_t (z : t) = Sexp.Atom (Z.to_string z)

let t_of_sexp = function
  | Sexp.Atom s -> Z.of_string s
  | _ -> failwith "Big_int.t must be an atom"
;;
