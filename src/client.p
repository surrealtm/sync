Client :: struct {
    connection: Virtual_Connection;
    message_callbacks: Message_Callbacks;
    registry: File_Registry;
}


/* General client setup, called once */

create_client :: (client: *Client, scratch_arena: *Memory_Arena, scratch_allocator: *Allocator) -> bool {
    create_file_registry(*client.registry, scratch_arena, scratch_allocator, "run_tree/client");
    return connect_client(client, "localhost");
}

destroy_client :: (client: *Client) {
    disconnect_client(client);
    destroy_file_registry(*client.registry);
}

update_client :: (client: *Client) {
    if client.connection.status == .Closed return;
    
    while read_packet(*client.connection) {
        parse_all_packet_messages(*client.connection.incoming_packet, *client.message_callbacks);
    }
}


/* Network management */

connect_client :: (client: *Client, host: string) -> bool {
    client.message_callbacks.user_pointer    = client;
    client.message_callbacks.on_create_file  = client_on_create_file;
    client.message_callbacks.on_file_content = client_on_file_content;
    
    success := create_client_connection(*client.connection, .TCP, host, SYNC_PORT);
    if !success return false;
    
    print("Successful client start.\n");
    return true;
}

disconnect_client :: (client: *Client) {
    destroy_connection(*client.connection);
    print("Destroyed the client.\n");
}



/* Message Callbacks */

client_on_create_file :: (client: *Client, message: *Create_File_Message) {
    register_file_id(*client.registry, message.file_id, message.file_size, message.file_path);
}

client_on_file_content :: (client: *Client, message: *File_Content_Message) {
    entry := get_file_entry_by_id(*client.registry, message.file_id);

    if !entry {
        print("No entry found under id '%' in the local registry.\n", message.file_id);
        return;
    }

    file_information, success := get_file_information(entry.file_path);

    assert(success && file_information.file_size == message.file_offset, "Invalid File Entry");
    write_file(entry.file_path, message.file_data, true);
}
