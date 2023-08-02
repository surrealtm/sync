Server :: struct {
    listener: Virtual_Connection;
}

create_server :: (server: *Server) -> bool {
    success := create_server_connection(*server.listener, .TCP, SYNC_PORT);    
    return success;
}

destroy_server :: (server: *Server) {
    destroy_server_connection(*server.listener);
}

update_server :: (server: *Server) -> bool {
    incoming, success := accept_incoming_client_connection(*server.listener);
    if !success return false;

    print("Connected to client.\n");
    return true;
}
