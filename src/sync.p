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
    if !create_client(*sync.client, "localhost") return -1;

    while !sync.quit && sync.client.connection.status != .Closed {
        update_client(*sync.client);
        Sleep(16);
    }

    destroy_client(*sync.client);
    return 0;
}

sync :: (argcount: s64, args: *cstring) -> s64 {
    sync: Sync;

#if BUILD_SERVER {
    CreateThread(null, 0, sync_server, *sync, 0, null);
}

#if BUILD_CLIENT {
    sync_client(*sync);
}
    
    return 0;
}

// The command to compile and run this application is:
//   prometheus src/sync.p -o:run_tree/sync.exe -run

main :: (argcount: s64, args: *cstring) -> s64 {
    return sync(argcount, args);
}
