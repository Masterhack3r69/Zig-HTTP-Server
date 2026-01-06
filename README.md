# Zig HTTP Server

A multithreaded HTTP/1.1 server written in Zig 0.15.x.  
This project focuses on explicit memory management, native networking, and
concurrent request handling using Zig’s standard library.

## Features

- **Multithreaded Architecture**  
  Uses `std.Thread.Pool` to handle multiple client connections concurrently,
  preventing slow requests from blocking the accept loop.

- **Static File Serving**  
  Serves files from a dedicated `public/` directory with path traversal
  protection.

- **Request Routing & Handlers**  
  Clean separation between HTTP parsing, routing logic, and request handlers.

- **Explicit Memory Management**  
  Careful allocator usage with well-defined ownership and lifetimes.
  Known heap allocations are bounded and freed correctly.

- **Native Socket I/O**  
  Built directly on `std.net` and `std.posix` for platform-aware networking
  (including correct Windows socket behavior).

- **Minimal HTTP Implementation**  
  Manual parsing of request lines and headers to demonstrate low-level HTTP
  server fundamentals.

## Getting Started

### Prerequisites

- [Zig 0.15.x](https://ziglang.org/download/)

### Installation & Usage

```bash
git clone https://github.com/Masterhack3r69/Zig-HTTP-Server
cd Zig-HTTP-Server
zig build run
```

The server listens on:

```
http://localhost:8080
```

### Example Endpoints

- `GET /` → Serves `public/index.html`
- `GET /hello` → Returns a plain text greeting
- Any other path → Attempted static file lookup

## Project Structure

```text
├── src/
│   ├── main.zig        # Listener, accept loop, thread pool
│   ├── router.zig      # Request routing
│   ├── handlers.zig    # HTTP handlers
│   ├── http/
│   │   ├── parser.zig
│   │   ├── request.zig
│   │   ├── response.zig
│   │   └── mime.zig
├── public/
│   └── index.html
└── build.zig
```

## Design Notes

- HTTP compression (gzip/brotli) is intentionally **not implemented**.
  In production environments, this server is intended to run behind a reverse
  proxy (e.g. Nginx or Cloudflare) which handles compression more efficiently.

- This project prioritizes clarity and correctness over feature completeness.
  Advanced features such as keep-alive request loops, streaming file responses,
  and graceful shutdown can be added incrementally.

## License

MIT

```

```
