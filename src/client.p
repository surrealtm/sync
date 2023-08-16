Client :: struct {
    connection: Virtual_Connection;
    message_callbacks: Message_Callbacks;
    registry: File_Registry;

    file_paths_to_send: [..]string; // A list of file paths which the client is trying to send, but did not yet receive a file id from the server. Once the server has assigned an id to that path, the id is sent to the client with a File_Info, and the client can begin sending the file
}


/* General client setup, called once */

create_client :: (client: *Client, scratch_arena: *Memory_Arena, scratch_allocator: *Allocator) -> bool {
    create_file_registry(*client.registry, scratch_arena, scratch_allocator, "."); // The registry folder of the client should always be the working directory, since the client should be run inside the directory in which the interesting local files are.
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
    client.message_callbacks.on_file_info    = client_on_file_info;
    client.message_callbacks.on_file_content = client_on_file_content;
    
    success := create_client_connection(*client.connection, .TCP, host, SYNC_PORT);
    if !success return false;
    
    print("Successfully connected to the server on %:%.\n", host, SYNC_PORT);
    return true;
}

disconnect_client :: (client: *Client) {
    destroy_connection(*client.connection);
    print("Destroyed the client.\n");
}



/* Message Callbacks */

client_on_file_info :: (client: *Client, message: *File_Info_Message) {
    entry := get_file_entry_by_id(*client.registry, message.file_id);
    action_prefix: string;
    
    if !entry {
        entry = create_file_entry(*client.registry);
        action_prefix = "Created";
    } else {
        action_prefix = "Replaced";
    }

    if !message.truncate_file action_prefix = "Registered";

    entry.file_id   = message.file_id;
    entry.file_size = message.file_size;
    entry.file_path = copy_string(message.file_path, Default_Allocator);
      
    print("% the local file '%' ('%', % bytes).\n", action_prefix, entry.file_path, entry.file_id, entry.file_size);

    complete_path := get_registry_file_path(*client.registry, message.file_path);
    if message.truncate_file   write_file(complete_path, "", false); // Create a new file or truncate an existing one, if this is the start of a file transfer

    // If this was a file info the client was waiting on to push to the server, then do that push now.
    for i := 0; i < client.file_paths_to_send.count; ++i {
        it := array_get_value(*client.file_paths_to_send, i);
        if compare_strings(it, message.file_path) {
            send_file_content(*client.connection, *client.registry, entry);
            array_remove(*client.file_paths_to_send, i);
            break;
        }
    }
}

client_on_file_content :: (client: *Client, message: *File_Content_Message) {
    entry := get_file_entry_by_id(*client.registry, message.file_id);

    if !entry {
        print("No entry found under the id '%' in the local registry.\n", message.file_id);
        return;
    }

    complete_path := get_registry_file_path(*client.registry, entry.file_path);

    file_information, success := get_file_information(complete_path);

    assert(success && file_information.file_size == message.file_offset, "Invalid File Entry");
    write_file(complete_path, message.file_data, true);
}
