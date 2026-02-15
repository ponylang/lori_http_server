# HTTP Server for Pony

## Building

```
make          # build and run tests
make test     # same as above
make clean    # clean build artifacts
```

## Architecture

Package: `http_server` (repo name is `lori_http_server`, but the Pony package name is `http_server`)

Built on lori (v0.8.1). Lori provides raw TCP I/O with a connection-actor model: `_on_received(data: Array[U8] iso)` for incoming data, `TCPConnection.send(data): (SendToken | SendError)` for outgoing, plus backpressure notifications and SSL support.

### Key design decisions

**Single-actor connection model**: Unlike `ponylang/http_server` (which uses two actors per connection with message-passing between them), this library keeps everything in one actor per connection: TCP I/O, parsing, handler dispatch, and response sending. The handler's `ref` methods run synchronously inside the connection actor. No unnecessary actor boundaries.

**Parser callback is `ref`, not `tag`**: The parser runs inside the connection actor, so its callback interface uses `fun ref` methods (synchronous calls), not `be` behaviors (actor messages). This avoids the extra actor hop that `ponylang/http_server` requires.

**Relationship to `ponylang/http_server`**: That project is built on the stdlib `net` package and has actor-interaction issues we want to avoid. We may borrow internal logic (e.g., parsing techniques) but the overall architecture and actor interactions are designed fresh around lori's model.

### Implementation plan

See [Discussion #2](https://github.com/ponylang/lori_http_server/discussions/2) for the phased implementation plan.

## File Layout

- `http_server/` — main package source
- `examples/` — example programs
