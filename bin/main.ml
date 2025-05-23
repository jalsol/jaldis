open Core
open Async

let run ~uppercase ~port =
  let host_and_port =
    Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port)
      (fun _addr r w ->
         Pipe.transfer
           (Reader.pipe r)
           (Writer.pipe w)
           ~f:(if uppercase then String.uppercase else Fn.id))
  in
  ignore host_and_port;
  Deferred.never ()
;;

let () =
  [%map_open.Command
    let uppercase = flag "-uppercase" no_arg ~doc:"Convert to uppercase"
    and port = flag "-port" (optional_with_default 6969 int) ~doc:"Port (default 6969)" in
    fun () -> run ~uppercase ~port]
  |> Command.async ~summary:"Echo server"
  |> Command_unix.run
;;
