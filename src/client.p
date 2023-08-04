Client :: struct {
    connection: Virtual_Connection;
}

create_client :: (client: *Client, host: string) -> bool {
    success := create_client_connection(*client.connection, .TCP, host, SYNC_PORT);
    return success;
}

destroy_client :: (client: *Client) {
    destroy_client_connection(*client.connection);
    print("Destroyed the client.\n");
}

update_client :: (client: *Client) -> bool {
    return true;
}
