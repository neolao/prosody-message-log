-- Prosody IM
-- Copyright (C) 2013 neolao
--

local jid_bare = require "util.jid".bare;
local jid_split = require "util.jid".split;
local stat, mkdir = require "lfs".attributes, require "lfs".mkdir;

-- Create the logging directory
local log_base_path = module:get_option("message_logging_dir", prosody.paths.data.."/message_logs");
if not stat(log_base_path) then
    mkdir(log_base_path);
end


-- Get a filesystem-safe string
local function fsencode_char(c)
    return ("%%%02x"):format(c:byte());
end
local function fsencode(s)
    return (s:gsub("[^%w._-@]", fsencode_char):gsub("^%.", "_"));
end

-- Handle incoming messages
local function incoming_message(event)
    local origin, stanza = event.origin, event.stanza;

    -- Do nothing if it is an error message
    local message_type = stanza.attr.type;
    if message_type == "error" then return; end

    -- Get the body
    -- If the body is empty, then do nothing
    local from, to = jid_bare(stanza.attr.from), jid_bare(stanza.attr.to);
    local body = stanza:get_child("body");
    if not body then return; end
    body = body:get_text();

    -- Get the file path
    -- Create the directory if necessary
    local directory_path = log_base_path.."/"..fsencode(to);
    if not stat(directory_path) then
        mkdir(directory_path);
    end
    local file_date = os.date("%Y-%m-%d");
    local file_path = directory_path.."/"..file_date.."_"..from..".txt";

    -- Append the message to the log file
    local file = io.open(file_path, "a");
    file:write("["..os.date("%X").."] ");
    file:write(from..": ");
    file:write(body);
    file:write("\n");
    file:flush();
    file:close();

    -- Update the file mode
    os.execute("chmod 755 "..file_path);
end

-- Handle outgoing messages
local function outgoing_message(event)
    local origin, stanza = event.origin, event.stanza;

    -- Do nothing if it is an error message
    local message_type = stanza.attr.type;
    if message_type == "error" then return; end

    -- Get the body
    -- If the body is empty, then do nothing
    local from, to = jid_bare(stanza.attr.from), jid_bare(stanza.attr.to);
    local body = stanza:get_child("body");
    if not body then return; end
    body = body:get_text();

    -- Get the file path
    -- Create the directory if necessary
    local directory_path = log_base_path.."/"..fsencode(from);
    if not stat(directory_path) then
        mkdir(directory_path);
    end
    local file_date = os.date("%Y-%m-%d");
    local file_path = directory_path.."/"..file_date.."_"..to..".txt";

    -- Append the message to the log file
    local file = io.open(file_path, "a");
    file:write("["..os.date("%X").."] ");
    file:write(from..": ");
    file:write(body);
    file:write("\n");
    file:flush();
    file:close();

    -- Update the file mode
    os.execute("chmod 755 "..file_path);
end

-- Register the handlers
module:hook("message/bare", incoming_message, 1);
module:hook("message/full", incoming_message, 1);
module:hook("pre-message/bare", outgoing_message, 1);
module:hook("pre-message/full", outgoing_message, 1);
module:hook("pre-message/host", outgoing_message, 1);
