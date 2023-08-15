get_next_word_in_input :: (input: *string) -> string {
    // Eat empty characters before the word
    argument_start: u32 = 0;
    while argument_start < input.count && input.data[argument_start] == ' '    argument_start += 1;
    
    if argument_start == input.count {
        // There was no more word in the input string, set the start and end pointer to an invalid state
        ~input = "";
        return "";
    }
    
    argument: string = ---;
    
    // Read the input string until the end of the word.
    if input.data[argument_start] == '"' {
        // If the start of this word is a quotation mark, then the word end is marked by the next
        // quotation mark. Spaces are ignored in this case.
        argument_end, found_quote := search_string_from(~input, '"', argument_start + 1);
        if !found_quote {
            // While this is technically invalid syntax, we'll allow it for now. If no closing quote is found, just
            // assume that the argument is the rest of the input string.
            argument = substring_view(~input, argument_start, input.count);
            ~input = "";
        } else {
            // Exclude the actual quote characters from the output string
            argument = substring_view(~input, argument_start + 1, argument_end);
            ~input = substring_view(~input, argument_end + 1, input.count);
        }
    } else {
        // The word goes until the next encountered space character.
        argument_end, found_space := search_string_from(~input, ' ', argument_start);
        if !found_space    argument_end = input.count;
        argument = substring_view(~input, argument_start, argument_end);
        ~input = substring_view(~input, argument_end, input.count);
    }
    
    return argument;
}


parse_command :: (sync: *Sync, input: string) {
    // Parse the actual command name
    command_name := get_next_word_in_input(*input);
    
    command_arguments: [..]string;
    command_arguments.allocator = *sync.scratch_allocator;
    
    // Parse all the arguments
    while input.count {
        argument := get_next_word_in_input(*input);
        if argument.count array_add(*command_arguments, argument);
    }

    // Dispatch the actual command. Since this application will only support a few commands, there is no
    // need for something fancy here.
    
    if compare_strings(command_name, "quit") {
        sync.quit = true;
    } else if compare_strings(command_name, "pull") {
        request_file(*sync.client.connection, array_get_value(*command_arguments, 0)); // @Cleanup proper command args check.
    } else if compare_strings(command_name, "list") {
        list_file_registry(*sync.server.registry, "Server");
        list_file_registry(*sync.client.registry, "Client");
    } else if compare_strings(command_name, "sync") {
        sync_file_registry(*sync.client.connection);
    } else
        print("Unknown command '%'. Try 'help'.\n", command_name);
}
