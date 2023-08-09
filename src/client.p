Client :: struct {
    connection: Virtual_Connection;
    message_callbacks: Message_Callbacks;
}

connect_client :: (client: *Client, host: string) -> bool {
    client.message_callbacks.user_pointer   = client;
    client.message_callbacks.on_create_file = client_on_create_file;

    success := create_client_connection(*client.connection, .TCP, host, SYNC_PORT);
    if !success return false;

    packet: Packet;
    send_packet(*client.connection, *packet);
    
    print("Successful client start.\n");
    return true;
}

disconnect_client :: (client: *Client) {
    destroy_connection(*client.connection);
    print("Destroyed the client.\n");
}

update_client :: (client: *Client) {
    if client.connection.status == .Closed return;
    
    while read_packet(*client.connection) parse_all_packet_messages(*client.connection.incoming_packet, *client.message_callbacks);
}



/* Message Callbacks */

client_on_create_file :: (client: *Client, message: *Create_File_Message) {
    print("Creating file on client: '%' ('%', % bytes).\n", message.file_path, message.file_id, message.file_size);
}
