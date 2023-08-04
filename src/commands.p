parse_command :: (sync: *Sync, input: string) {
    if compare_strings(input, "quit") {
        sync.quit = true;
        return;
    }
}
