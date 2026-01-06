# Zig HTTP Server

A high-performance, multithreaded HTTP server written in Zig. This project demonstrates modern Zig patterns for networking, memory management, and concurrent programming.

## Features

- **Multithreaded Architecture**: Uses Zig's `Thread.Pool` to handle hundreds of concurrent requests efficiently.
- **Streaming File I/O**: Serves large static files in chunks to maintain a low memory footprint.
- **Graceful Shutdown**: Listens for termination signals (Ctrl+C) and ensures all active requests finish before shutting down.
- **Request Logging**: Automated logging of HTTP method, path, status codes, and precise request duration.
- **Security**: Built-in path traversal protection for static files.
- **Persistent Connections**: Support for HTTP/1.1 Keep-Alive.
- **Modular Design**: Clean separation between parser, router, handlers, and the core server loop.

## Getting Started

### Prerequisites

- [Zig 0.15.+](https://ziglang.org/download/)

### Installation & Usage

1. **Clone the repository**:

   ```bash
   git clone <repo-url>
   cd zig-http-server
   ```

2. **Build and Run**:

   ```bash
   zig build run
   ```

   The server will start on `http://localhost:8080`.

3. **Try the Endpoints**:
   - `GET /`: Serves `public/index.html`.
   - `GET /hello`: Returns a plain text greeting.
   - `POST /echo`: Echoes back the request body.

## Project Structure

```text
├── src/
│   ├── main.zig        # Entry point, socket loop, and signal handling
│   ├── router.zig      # Request routing logic
│   ├── handlers.zig    # HTTP request handlers (static files, echo, etc.)
│   ├── http/
│   │   ├── parser.zig  # Request line and header parsing
│   │   ├── request.zig # Request data structures
│   │   ├── response.zig# Response helpers (headers, body)
│   │   └── mime.zig    # MIME type detection
│   └── ...
├── public/             # Static file directory
└── build.zig           # Zig build configuration
```

## Technical Highlights

- **Arena Allocation**: Uses `std.heap.ArenaAllocator` per request to simplify memory management and prevent leaks.
- **Zero-Copy Parsing**: Leverages Zig's slicing for efficient header identification.
- **Native Networking**: Uses `std.net` and `std.posix` for platform-specific socket optimization.

## License

MIT
