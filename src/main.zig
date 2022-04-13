const std = @import("std");
const Allocator = std.mem.Allocator;

const Token = struct {
    id: TokenId,

    pub const TokenId = enum {
        start,
    };
};

const ScannerError = error{InvalidString};
const scanner_error_to_string;

const Scanner = struct {
    const Self = @This();
    const Tokens = std.ArrayList(Token);

    code: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, code: []u8) Self {
        return Self{
            .code = code,
            .allocator = allocator,
        };
    }

    pub fn scanTokens(self: *Self) Tokens {
        var tokens = Tokens.init(self.allocator);
        try tokens.append(Token{ .id = Token.TokenId.start });

        return tokens;
    }
};

pub fn run(allocator: Allocator, code: []u8) void {
    var scanner = Scanner.init(allocator, code);
    const list = scanner.scanTokens();

    for (list.items) |v| {
        std.debug.print("{s}", .{v});
    }
}

pub fn runFile(allocator: Allocator, file_name: []u8) !void {
    const file = try std.fs.cwd().openFile(file_name, .{});
    const file_content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(file_content);
    run(allocator, file_content);
}

pub fn runPrompt(allocator: Allocator) !void {
    const stdin = std.io.getStdIn().reader();

    while (true) {
        std.debug.print("\n> ", .{});
        var line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024 * 1024);
        if (line != null and line.?.len > 0) {
            run(allocator, line.?);
        } else {
            break;
        }
    }
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 2) {
        std.log.err("Usage: zlox [script]", .{});
        std.process.exit(64);
    } else if (args.len == 2) {
        try runFile(allocator, args[1]);
    } else {
        try runPrompt(allocator);
    }
}
