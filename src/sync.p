// --- Modules
#load "basic.p";
#load "socket.p";
#load "threads.p";
#load "string_builder.p";

// --- Project Source Files
#load "server.p";
#load "client.p";
#load "commands.p";
#load "messages.p";
#load "registry.p";

SYNC_PORT :: 0xfefe;

Sync_Status :: enum {
    Closed;
    Running;
}

Sync :: struct {
    quit: bool;
    server: Server;
    client: Client;

    server_thread: Thread;
    client_thread: Thread;

    server_status: Sync_Status = .Closed;
    client_status: Sync_Status = .Closed;
    
    scratch_arena:  Memory_Arena;
    scratch_allocator: Allocator; // @Cleanup right now this allocator (or rather the underlying memory arena) never actually gets reset, since the multithreaded nature of this program might lead to issues. We probably actually need an arena for each thread anyway, and therefore have both the server and the client create one for themselves.
}

sync_server_loop :: (sync: *Sync) -> u32 {
    if !create_server(*sync.server, *sync.scratch_arena, *sync.scratch_allocator) return -1;

    sync.server_status = .Running;
    
    while !sync.quit && sync.server.listener.status != .Closed {
        update_server(*sync.server);
        Sleep(16);
    }

    sync.server_status = .Closed;
    
    destroy_server(*sync.server);
    return 0;
}

start_sync_server :: (sync: *Sync) {
    sync.server_thread = create_thread(sync_server_loop, sync);
}

sync_client_loop :: (sync: *Sync) -> u32 {
    if !create_client(*sync.client, *sync.scratch_arena, *sync.scratch_allocator) return -1;

    sync.client_status = .Running;
    
    while !sync.quit && sync.client.connection.status != .Closed {
        update_client(*sync.client);
        Sleep(16);
    }

    sync.client_status = .Closed;
    
    destroy_client(*sync.client);
    return 0;
}

start_sync_client :: (sync: *Sync, host: string) {
    sync.client.host = host;
    sync.client_thread = create_thread(sync_client_loop, sync);
}

sync :: (argcount: s64, args: *cstring) -> s64 {
    sync: Sync;

    // Set up memory management
    create_memory_arena(*sync.scratch_arena, 4 * MEGABYTES);
    sync.scratch_allocator = memory_arena_allocator(*sync.scratch_arena);
    
    // Disable the input echo mode, since we will echo input back to the user ourselves. This is only nice for
    // CmdX, but completely hides the current text input for other terminals...
    //SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT);
    
    // The main thread just waits for command input from the user until the user quits the application.
    while !sync.quit {
        input := read_line_from_stdin();
        parse_command(*sync, input);
    }

    // Since the main thread only terminates when the quit variable of the sync state is false, both of these
    // threads (if they were ever actually created) should also terminate any time now.
    print("Exiting sync...\n");
    join_thread(*sync.server_thread);
    join_thread(*sync.client_thread);
    print("Goodbye.\n");
    
    return 0;
}

// The command to compile and run this application is:
//   prometheus src/sync.p -o:run_tree/sync.exe -run

main :: (argcount: s64, args: *cstring) -> s64 {
    return sync(argcount, args);
}
