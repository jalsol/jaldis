type t

val init : string -> t
val parse_next : t -> (t * Ast.t) Core.Or_error.t
