// --- Modules
#load "basic.p";
#load "socket.p";
#load "threads.p";

// --- Project Source Files
#load "server.p";
#load "client.p";
#load "commands.p";
#load "messages.p";
#load "registry.p";

BUILD_SERVER :: true;
BUILD_CLIENT :: true;

SYNC_PORT :: 0xfefe;

Sync :: struct {
    quit: bool;
    server: Server;
    client: Client;

    server_thread: Thread;
    client_thread: Thread;
}



sync_server :: (sync: *Sync) -> u32 {
    if !create_server(*sync.server) return -1;

    while !sync.quit && sync.server.listener.status != .Closed {
        update_server(*sync.server);
        Sleep(16);
    }
    
    destroy_server(*sync.server);
    return 0;
}

sync_client :: (sync: *Sync) -> u32 {
    if !create_client(*sync.client) return -1;

    while !sync.quit && sync.client.connection.status != .Closed {
        update_client(*sync.client);
        Sleep(16);
    }

    destroy_client(*sync.client);
    return 0;
}

sync :: (argcount: s64, args: *cstring) -> s64 {
    sync: Sync;

    // Disable the input echo mode, since we will echo input back to the user ourselves.
    SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT);

    // Create the threads for the server and the client. Later on, these should probably be created dynamically,
    // maybe defined by some config whether to start the server / client.
#if BUILD_SERVER {
    sync.server_thread = create_thread(sync_server, *sync);
}

#if BUILD_CLIENT {
    sync.client_thread = create_thread(sync_client, *sync);
}

    // The main thread just waits for command input from the user until the user quits the application.
    while !sync.quit {
        input := read_line_from_stdin();
        print("> '%'\n", input);
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
