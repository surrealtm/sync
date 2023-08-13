File_Id :: u64;

File_Entry :: struct {
    file_id:   File_Id;
    file_size: u64;
    file_path: string;
}

File_Registry :: struct {
    scratch_allocator: *Allocator;
    folder_path: string;
    entries: [..]File_Entry;
}

create_file_registry :: (registry: *File_Registry, scratch_allocator: *Allocator, folder: string) {
    register.scratch_allocator = scratch_allocator;
    registry.folder_path = folder;
}

destroy_file_registry :: (registry: *File_Registry) {
    // @@Leak the entries' file_paths are currently never freed
    array_clear(*registry.entries);
}


get_registry_file_path :: (registry: *File_Registry, file_path: string) -> string {
    builder: String_Builder;
    create_string_builder(*builder, registry.scratch_allocator);
    append_string(*builder, registry.folder_path);
    append_character(*builder, '/');
    append_string(*builder, file_path);
    return finish_string_builder(*builder, file_path);
}


create_file_entry :: (registry: *File_Registry) -> *File_Entry {
    entry := array_push(*registry.entries);
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
