File_Id :: u64;

File_Entry :: struct {
    file_id:   File_Id; // A non-persistent, global id used to identify file entries across the network. For this id to be global, only the server gets to create them. When users want to upload a file, they must first reserve an id from the server, and then the actual file transfer can happen
    file_size: u64;
    file_path: string;
}

File_Registry :: struct {
    scratch_arena: *Memory_Arena;
    scratch_allocator: *Allocator;

    folder_path: string;
    entries: [..]File_Entry;

    id_counter: File_Id = 1;
}

create_file_registry :: (registry: *File_Registry, scratch_arena: *Memory_Arena, scratch_allocator: *Allocator, folder: string) {
    registry.scratch_arena     = scratch_arena;
    registry.scratch_allocator = scratch_allocator;
    registry.folder_path       = folder;

    create_folder(registry.folder_path); // Make sure the registry folder actually exists, so that future io operations can just assume this is the case
}

destroy_file_registry :: (registry: *File_Registry) {
    // @@Leak the entries' file_paths are currently never freed
    array_clear(*registry.entries);
}

list_file_registry :: (registry: *File_Registry, prefix: string) {
    print("=== FILES: % (%) ===\n", prefix, registry.folder_path);

    for i := 0; i < registry.entries.count; ++i {
        entry := array_get(*registry.entries, i);
        print("  %: '%' (% bytes)\n", entry.file_id, entry.file_path, entry.file_size);
    }

    print("=== FILES: % (%) ===\n", prefix, registry.folder_path);
}


register_loose_files :: (registry: *File_Registry) {
    // Go through all files in the registry folder and create an entry for them, if they do not already have one.
    files := get_files_in_folder(registry.folder_path, registry.scratch_allocator);

    for i := 0; i < files.count; ++i {
        it := array_get_value(*files, i);

        if !get_file_entry_by_path(registry, it) {
            // No entry for that path yet, create a new one
            complete_path := get_registry_file_path(registry, it);
            file_information, success := get_file_information(complete_path);

            entry := create_file_entry(registry);
            entry.file_path = copy_string(it, Default_Allocator);
            entry.file_size = file_information.file_size;
        }
    }
}


get_registry_file_path :: (registry: *File_Registry, file_path: string) -> string {
    builder: String_Builder;
    create_string_builder(*builder, registry.scratch_arena);
    append_string(*builder, registry.folder_path);
    append_character(*builder, '/');
    append_string(*builder, file_path);
    return finish_string_builder(*builder);
}


create_file_entry :: (registry: *File_Registry) -> *File_Entry {
    entry := array_push(*registry.entries);
    entry.file_id = registry.id_counter;
    ++registry.id_counter;
    return entry;
}


get_file_entry_by_id :: (registry: *File_Registry, id: File_Id) -> *File_Entry {
    entry: *File_Entry = null;

    for i := 0; i < registry.entries.count; ++i {
        it := array_get(*registry.entries, i);
        if it.file_id == id {
            entry = it;
            break;
        }
    }

    return entry;
}

get_file_entry_by_path :: (registry: *File_Registry, path: string) -> *File_Entry {
    entry: *File_Entry = null;

    for i := 0; i < registry.entries.count; ++i {
        it := array_get(*registry.entries, i);
        if compare_strings(it.file_path, path) {
            entry = it;
            break;
        }
    }
    
    return entry;
}
