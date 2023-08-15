Server :: struct {
    listener: Virtual_Connection;
    registry: File_Registry;
}

create_server :: (server: *Server, scratch_arena: *Memory_Arena) -> bool {
    create_file_registry(*server.registry, scratch_arena, "run_tree/server");

    success := create_server_connection(*server.listener, .TCP, SYNC_PORT);    
    if !success return false;

    print("Successful server start.\n");
    return true;
}

destroy_server :: (server: *Server) {
    destroy_connection(*server.listener);
    destroy_file_registry(*server.registry);
    print("Destroyed the server.\n");
}

update_server :: (server: *Server) {
    if server.listener.status == .Closed return;

    incoming, success := accept_incoming_client_connection(*server.listener);
    if !success return;
    
    print("Connected to remote client.\n");

    fake_entry := File_Entry.{ 1, 32, "test.txt" };
    send_file(*incoming, *server.registry, *fake_entry);
}
