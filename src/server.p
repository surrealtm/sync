// This server uses a non-blocking architecture to support a lot of clients one a single thread, since that seems
// more resource friendly than creating a new thread for every client connecting. Also seems simpler.
// Maybe in the future one could experiment with something like an FD-Set, though I am currently not sure how
// to implement something like this in this language.
Server :: struct {
    listener: Virtual_Connection;
    registry: File_Registry;
    message_callbacks: Message_Callbacks;

    clients: [..]Virtual_Connection;
}

Server_Callback_Data :: struct {
    server: *Server;
    client: *Virtual_Connection;
}

create_server :: (server: *Server, scratch_arena: *Memory_Arena, scratch_allocator: *Allocator) -> bool {
    // The user pointer will be filled out individually for every client when it is handled.
    // Other message types which are not allowed from the client to the server do not need to be handled
    // here, therefore they do not require a callback.
    server.message_callbacks.on_file_request = server_on_file_request;
    
    create_file_registry(*server.registry, scratch_arena, scratch_allocator, "run_tree/server");
    register_loose_files(*server.registry);
    
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

    // Check for potentially connected clients
    incoming, success := accept_incoming_client_connection(*server.listener);
    if success {
        array_add(*server.clients, incoming);
        print("Connected to remote client.\n");
    }

    server_callback_data: Server_Callback_Data;
    server_callback_data.server = server;
    
    // Go through all connected clients and try to handle incoming data from them.
    for i := 0; i < server.clients.count; {
        client := array_get(*server.clients, i);
        server_callback_data.client = client;
        server.message_callbacks.user_pointer = *server_callback_data;
        
        while read_packet(client) {
            parse_all_packet_messages(*client.incoming_packet, *server.message_callbacks);
        }

        if client.status == .Closed {
            // Connection to the client was closed / lost. Remove them from list of connected clients.
            array_remove(*server.clients, i);
            print("Disconnected from remote client.\n");
        } else
            // Iterate to the next client
            ++i;
    }
}



/* Message callbacks */

server_on_file_request :: (data: *Server_Callback_Data, message: *File_Request_Message) {
    file := get_file_entry_by_path(*data.server.registry, message.file_path);
    if file {
        send_file(data.client, *data.server.registry, file);
    } else {
        print("Remote requested file '%', which is not in the local registry.\n", message.file_path);
    }
}
