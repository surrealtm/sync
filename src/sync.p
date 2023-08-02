// --- Modules
#load "basic.p";
#load "socket.p";

// --- Project Source Files
#load "server.p";
#load "client.p";

BUILD_SERVER :: true;
BUILD_CLIENT :: true;

SYNC_PORT :: 9876;

Sync :: struct {
    quit: bool;
    server: Server;
    client: Client;
}

sync_server :: (sync: *Sync) {
    if !create_server(*sync.server) return;

    while !sync.quit {
        if !update_server(*sync.server) sync.quit = true;

        Sleep(16);
    }
    
    destroy_server(*sync.server);
}

sync_client :: (sync: *Sync) {
    if !create_client(*sync.client, "localhost") return;

    while !sync.quit {
        if !update_client(*sync.client) sync.quit = true;

        Sleep(16);
    }

    destroy_client(*sync.client);
}

sync :: (argcount: s64, args: *cstring) -> s64 {
    sync: Sync;

#if BUILD_SERVER {
    sync_server(*sync);
}

#if BUILD_CLIENT {
    sync_client(*sync);
}
    
    return 0;
}

// The command to compile this application is:
//   prometheus src/sync.p -o:run_tree/sync.exe

main :: (argcount: s64, args: *cstring) -> s64 {
    return sync(argcount, args);
}
