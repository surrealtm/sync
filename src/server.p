Server :: struct {
    listener: Virtual_Connection;
}

create_server :: (server: *Server) -> bool {
    success := create_server_connection(*server.listener, .TCP, SYNC_PORT);    
    if !success return false;

    print("Successful server start.\n");
    return true;
}

destroy_server :: (server: *Server) {
    destroy_connection(*server.listener);
    print("Destroyed the server.\n");
}

update_server :: (server: *Server) {
    if server.listener.status == .Closed return;

    incoming, success := accept_incoming_client_connection(*server.listener);
    if !success return;
    
    print("Connected to remote client.\n");


    file_content := "Hello World, how are you doing";
    send_create_file_message(*incoming, .{ 1, file_content.count, "test.txt" });
    send_file_content_message(*incoming, .{ 1, 0, file_content });
}
