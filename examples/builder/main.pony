"""
HTTP server using ResponseBuilder to pre-build and cache responses.

Demonstrates `ResponseBuilder` for constructing pre-serialized responses
that bypass serialization on each request. The response is built once in
the handler factory and shared across all requests via `Responder.respond_raw()`.

This is useful for high-throughput endpoints serving static or semi-static
content where per-request serialization overhead matters.
"""
// In user code with corral, this would be: use http_server = "http_server"
use http_server = "../../http_server"
use lori = "lori"

actor Main
  new create(env: Env) =>
    let auth = lori.TCPListenAuth(env.root)
    let config = http_server.ServerConfig("localhost", "8080")
    http_server.Server(auth, _CachedFactory, config, _ServerNotify(env))

class val _ServerNotify is http_server.ServerNotify
  let _env: Env
  new val create(env: Env) => _env = env

  fun listening(server: http_server.Server tag) =>
    _env.out.print("Builder example listening on localhost:8080")

  fun listen_failure(server: http_server.Server tag) =>
    _env.out.print("Failed to start server")

  fun closed(server: http_server.Server tag) =>
    _env.out.print("Server closed")

class val _CachedFactory is http_server.HandlerFactory
  """
  Pre-builds a response once and shares it with every handler instance.

  Because `HandlerFactory` is `val`, the builder (`ref`) must be used inside
  a `recover val` block. The resulting `Array[U8] val` is immutable and
  safely shareable across connection actors.
  """
  let _response: Array[U8] val

  new val create() =>
    let body: String val = "Hello from the builder!"
    _response = recover val
      http_server.ResponseBuilder(http_server.StatusOK)
        .add_header("Content-Type", "text/plain")
        .add_header("Content-Length", body.size().string())
        .finish_headers()
        .add_chunk(body)
        .build()
    end

  fun apply(): http_server.Handler ref^ =>
    _CachedHandler(_response)

class ref _CachedHandler is http_server.Handler
  """
  Handler that sends a pre-built cached response for every request.

  No per-request serialization — just pushes the cached bytes through
  the response queue.
  """
  let _response: Array[U8] val

  new create(response: Array[U8] val) =>
    _response = response

  fun ref request_complete(
    responder: http_server.Responder,
    body: http_server.RequestBody)
  =>
    responder.respond_raw(_response)
