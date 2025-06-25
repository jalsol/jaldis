open Core
open Async
open Resp
open Server

let handle_connection _socket r w =
  let handle_one msg =
    Writer.write w @@ Serializer.serialize @@ Commands.handle_msg msg;
    return ()
  in
  match%bind Angstrom_async.parse_many Parser.parse handle_one r with
  | Ok () -> Writer.close w
  | Error err ->
    Writer.writef w "-ERR:%s" err;
    Writer.close w
;;

let run ~port =
  let host_and_port =
    Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port)
      handle_connection
  in
  Clock.every ~continue_on_error:true (Time_float.Span.of_int_ms 100) (fun () ->
    ignore (Storage.sweep_expired ~quota:50 ()));
  ignore host_and_port;
  Deferred.never ()
;;

let () =
  [%map_open.Command
    let port = flag "-port" (optional_with_default 6969 int) ~doc:"Port (default 6969)" in
    fun () -> run ~port]
  |> Command.async ~summary:"Echo server"
  |> Command_unix.run
;;
