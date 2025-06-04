open Core
open Async

let run ~host ~port =
  Tcp.connect (Tcp.Where_to_connect.of_host_and_port { host; port })
  >>= fun (_, server_reader, server_writer) ->
  let input_and_send () =
    Reader.stdin
    |> Lazy.force
    |> Reader.read_line
    >>= function
    | `Eof -> Deferred.unit
    | `Ok input ->
      Writer.write_line server_writer input;
      Writer.flushed server_writer
  in
  let rec loop () =
    let%bind () = input_and_send () in
    Reader.read_line server_reader
    >>= function
    | `Eof ->
      print_string "server> eof";
      Writer.close server_writer
    | `Ok response ->
      printf "server> %s\n" response;
      loop ()
  in
  loop ()
;;

let () =
  [%map_open.Command
    let host = flag "-host" (required string) ~doc:"jaldis host"
    and port =
      flag "-port" (optional_with_default 6969 int) ~doc:"jaldis port (default 6969)"
    in
    fun () -> run ~host ~port]
  |> Command.async ~summary:"Echo server"
  |> Command_unix.run
;;
