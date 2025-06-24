# jaldis

**jaldis** is a Redis-compatible key-value store implemented in OCaml.

Demonstration video: [https://www.youtube.com/watch?v=M3a44Lh2qUo](https://www.youtube.com/watch?v=M3a44Lh2qUo)

## Features

### Data Types
- **Strings** - Store and retrieve text values
- **Lists** - Ordered collections with push/pop operations
- **Sets** - Unordered collections of unique elements

### Core Operations
- `SET/GET` - Basic key-value operations
- `DEL` - Delete keys
- `KEYS` - List all keys
- `FLUSHDB` - Clear all data

### List Operations
- `LPUSH/RPUSH` - Push elements to front/back
- `LPOP/RPOP` - Pop elements from front/back (with optional count)
- `LLEN` - Get list length
- `LRANGE` - Get elements in range

### Set Operations
- `SADD` - Add elements to set
- `SREM` - Remove elements from set
- `SCARD` - Get set size
- `SMEMBERS` - Get all set members
- `SINTER` - Set intersection
- `SISMEMBER` - Check membership

### Expiration & TTL
- `EXPIRE` - Set key expiration in seconds
- `TTL` - Get time-to-live for key
- **Automatic cleanup** - Background sweep removes expired keys

### Protocol Support
- **RESP (Redis Serialization Protocol)** - Full compatibility with Redis clients
- **TCP server** - Standard Redis port (6379) or custom port

## Installation

### Prerequisites
- OCaml 5.0+
- Dune 3.17+
- OPAM package manager

### Dependencies
```bash
opam install core async ppx_jane zarith angstrom angstrom-async
```

### Build
```bash
git clone https://github.com/jalsol/jaldis.git
cd jaldis
dune build
```

## Usage

### Start Server
```bash
# Default port 6969
dune exec server

# Custom port
dune exec server -- -port 6379
```

## Architecture

### Core Components
- **Storage Engine** - In-memory hash tables with expiration tracking
- **RESP Parser** - Full Redis protocol implementation
- **Command Handler** - Redis-compatible command processing
- **Async Server** - High-performance TCP server using Jane Street's Async

### Performance Features
- **Optimized Expiration** - Hybrid sweep strategy (O(1) for large datasets)
- **Memory Efficient** - Separate storage and expiration tracking
- **Non-blocking** - Asynchronous I/O for concurrent connections

### Key Optimizations
- **Small Tables** (≤100 keys): Full scan with early termination
- **Large Tables** (>100 keys): Probabilistic sampling to avoid O(n) scans
- **Background Cleanup** - Automatic expired key removal every 100ms

## Development

### Run Tests
```bash
dune test
```

### Format Code
```bash
dune fmt
```

### Project Structure
```
jaldis/
├── bin/           # Server executable
├── misc/          # Utilities and test scripts
├── resp/          # RESP protocol implementation
├── server/        # Core storage and command handling
└── test/          # Unit and integration tests
```

### Key Modules
- `Storage` - Core key-value storage with TTL support
- `Commands` - Redis command implementations
- `Parser/Serializer` - RESP protocol handling
- `Rstring/Rlist/Rset` - Data type specific operations

## Compatibility

### Redis Features Supported
- ✅ Core data types (String, List, Set)
- ✅ Expiration and TTL
- ✅ RESP protocol
- ✅ Most common commands
- ✅ Redis client compatibility

### Not Yet Implemented
- Hash data type
- Sorted sets
- Pub/Sub
- Persistence
- Clustering
- Transactions

## License

MIT License - see [LICENSE](LICENSE) file for details.
