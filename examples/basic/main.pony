"""
Basic HTTP server that responds to every request with "Hello, World!".

Demonstrates the core API: the user's listener actor implements
`lori.TCPListenerActor` directly, creating `HTTPServerActor` instances in
`_on_accept`. Also demonstrates query parameter extraction from the
pre-parsed URI: a `?name=X` parameter customizes the greeting.

Body data arrives via `body_chunk()` callbacks. This example ignores
request bodies — for body accumulation, see the streaming example.
"""
use http_server = "../../http_server"
use uri = "uri"
use lori = "lori"
use ssl_net = "ssl/net"
use "time"

actor Main is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _env: Env
  let _config: http_server.ServerConfig
  let _server_auth: lori.TCPServerAuth

  new create(env: Env) =>
    _env = env
    let auth = lori.TCPListenAuth(env.root)
    _server_auth = lori.TCPServerAuth(auth)
    _config = http_server.ServerConfig("localhost", "8080")
    _tcp_listener = lori.TCPListener(auth, "localhost", "8080", this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor =>
    _HelloServer(_server_auth, fd, _config, None, None)

  fun ref _on_listening() =>
    _env.out.print("Server listening on localhost:8080")

  fun ref _on_listen_failure() =>
    _env.out.print("Failed to start server")

  fun ref _on_closed() =>
    _env.out.print("Server closed")

actor _HelloServer is http_server.HTTPServerActor
  var _http: http_server.HTTPServer = http_server.HTTPServer.none()
  var _request_count: USize = 0
  var _name: String val = "World"

  new create(
    auth: lori.TCPServerAuth,
    fd: U32,
    config: http_server.ServerConfig,
    ssl_ctx: (ssl_net.SSLContext val | None),
    timers: (Timers | None))
  =>
    _http = http_server.HTTPServer(auth, fd, ssl_ctx, this,
      config, timers)

  fun ref _http_connection(): http_server.HTTPServer => _http

  fun ref request(request': http_server.Request val) =>
    // Extract a "name" query parameter if present
    _name = "World"
    match request'.uri.query_params()
    | let params: uri.QueryParams val =>
      match params.get("name")
      | let name: String => _name = name
      end
    end

  fun ref request_complete(responder: http_server.Responder) =>
    _request_count = _request_count + 1
    let resp_body: String val =
      "Hello, " + _name + "! (request " + _request_count.string() + ")"
    let response = http_server.ResponseBuilder(http_server.StatusOK)
      .add_header("Content-Type", "text/plain")
      .add_header("Content-Length", resp_body.size().string())
      .finish_headers()
      .add_chunk(resp_body)
      .build()
    responder.respond(response)
