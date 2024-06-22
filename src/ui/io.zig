const std = @import("std");
const fileDialog = @import("../tinyfiledialog.zig");

var semaphore = std.Thread.Semaphore{};

pub const message = enum {
    none,
    done,
    open_select_folder_for_load_music,
};

pub const message_content = union(message) {
    none: void,
    done: void,
    open_select_folder_for_load_music: ?[][]u8,
};

var mailbox: message = undefined;
var mailbox_response: message_content = undefined;
var buffer: [1024 * 32]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
var allocator = fba.allocator();

pub fn loop() !void {
    loop: while (true) {
        semaphore.wait();
        fba.reset();

        switch (mailbox) {
            .none => {},
            .done => {
                break :loop;
            },
            .open_select_folder_for_load_music => {
                const path = fileDialog.tinyfd_selectFolderDialog("select folder", null);
                if (path == null) {
                    mailbox_response = message_content{ .open_select_folder_for_load_music = null };
                    continue :loop;
                }
                const path_zig_style: [:0]const u8 = std.mem.span(path);
                const dir_path = allocator.dupe(u8, path_zig_style) catch unreachable;
                const music_dir = std.fs.openDirAbsolute(dir_path, .{ .iterate = true }) catch unreachable;
                var music_dir_iterator = music_dir.iterate();
                var musics = std.ArrayList([]u8).init(allocator);

                while (try music_dir_iterator.next()) |entry| {
                    if (entry.kind == std.fs.File.Kind.directory) continue;
                    const entry_path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir_path, entry.name }) catch unreachable;
                    musics.append(try allocator.dupe(u8, entry_path)) catch unreachable;
                }

                mailbox_response = message_content{ .open_select_folder_for_load_music = musics.toOwnedSlice() catch unreachable };
            },
        }
    }
}

pub fn init() !void {
    const thread = try std.Thread.spawn(.{}, loop, .{});
    thread.detach();
}

pub fn postMessage(msg: message) void {
    mailbox = msg;
    semaphore.post();
}

pub fn getResponse() message_content {
    const msg = mailbox_response;
    mailbox_response = message_content{ .none = {} };
    return msg;
}
