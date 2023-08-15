parse_command :: (sync: *Sync, input: string) {
    if compare_strings(input, "quit") {
        sync.quit = true;
        return;
    } else if compare_strings(input, "request") {
        request_file(*sync.client.connection, "hello_world.txt");
    }
}
