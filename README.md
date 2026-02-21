# jaldis

*Didn't spend a penny on EngineerPro's course. Worshipped the almighty camel 🐫 instead.*

**jaldis** is a Redis-compatible key-value store implemented in OCaml.

Demonstration video: [https://www.youtube.com/watch?v=M3a44Lh2qUo](https://www.youtube.com/watch?v=M3a44Lh2qUo)

## Benchmarking

Performance benchmarks using `redis-benchmark` against jaldis server (in Release mode):

### Test Configuration
- **Hardware**: Intel Core i5-1135G7
- **OS**: Linux 6.18.7-arch1-1
- **OCaml**: 5.3.0
- **Network**: localhost
- **Test Parameters**: 1,000,000 `SET/GET` operations, 100 concurrent connections

```bash
# Standard benchmark
redis-benchmark -h 127.0.0.1 -p 6969 -n 1000000 -c 100 -t set,get --csv

# Pipelined benchmark (16 commands per pipeline)
redis-benchmark -h 127.0.0.1 -p 6969 -n 1000000 -c 100 -t set,get -P 16 --csv
```

### Results

#### Standard Mode (`-P 1`)
```
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","108026.36","0.851","0.224","0.879","1.247","1.551","14.343"
"GET","107411.38","0.853","0.216","0.879","1.295","1.655","13.455"
```

#### Pipelined Mode (`-P 16`)
```
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","244977.97","6.393","1.848","6.327","7.711","9.055","21.519"
"GET","296033.16","5.254","1.256","5.183","6.591","7.831","19.903"
```

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
dune build --release # Release mode
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
