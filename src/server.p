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

    send_create_file_message(*incoming, .{ 1, 9876, "test.txt" });
}
