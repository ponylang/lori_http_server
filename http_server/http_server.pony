"""
HTTP server for Pony, built on lori.

The user's listener actor implements `lori.TCPListenerActor` directly,
creating `HTTPServerActor` instances in `_on_accept`. Each connection
actor owns an `HTTPServer` that handles HTTP parsing and response
management, delivering HTTP events via `HTTPServerLifecycleEventReceiver`
callbacks.

```pony
use "http_server"
use lori = "lori"

actor Main is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _server_auth: lori.TCPServerAuth
  let _config: ServerConfig

  new create(env: Env) =>
    let auth = lori.TCPListenAuth(env.root)
    _server_auth = lori.TCPServerAuth(auth)
    _config = ServerConfig("localhost", "8080")
    _tcp_listener = lori.TCPListener(auth, "localhost", "8080", this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor =>
    MyServer(_server_auth, fd, _config, None, None)

actor MyServer is HTTPServerActor
  var _http: HTTPServer = HTTPServer.none()

  new create(auth: lori.TCPServerAuth, fd: U32,
    config: ServerConfig,
    ssl_ctx: (ssl_net.SSLContext val | None),
    timers: (Timers | None))
  =>
    _http = HTTPServer(auth, fd, ssl_ctx, this, config, timers)

  fun ref _http_connection(): HTTPServer => _http

  fun ref request_complete(responder: Responder) =>
    let body: String val = "Hello!"
    let response = ResponseBuilder(StatusOK)
      .add_header("Content-Length", body.size().string())
      .finish_headers()
      .add_chunk(body)
      .build()
    responder.respond(response)
```

For streaming responses, use chunked transfer encoding:

```pony
fun ref request_complete(responder: Responder) =>
  responder.start_chunked_response(StatusOK)
  responder.send_chunk("chunk 1")
  responder.send_chunk("chunk 2")
  responder.finish_response()
```

For HTTPS, store an `SSLContext val` in the listener and pass it through
in `_on_accept`:

```pony
use "http_server"
use "files"
use "ssl/net"
use lori = "lori"

actor Main is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _server_auth: lori.TCPServerAuth
  let _config: ServerConfig
  let _ssl_ctx: SSLContext val

  new create(env: Env) =>
    let sslctx = recover val
      SSLContext
        .> set_cert(
          FilePath(FileAuth(env.root), "cert.pem"),
          FilePath(FileAuth(env.root), "key.pem"))?
        .> set_client_verify(false)
        .> set_server_verify(false)
    end
    _ssl_ctx = sslctx
    let auth = lori.TCPListenAuth(env.root)
    _server_auth = lori.TCPServerAuth(auth)
    _config = ServerConfig("localhost", "8443")
    _tcp_listener = lori.TCPListener(auth, "localhost", "8443", this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor =>
    MyServer(_server_auth, fd, _config, _ssl_ctx, None)
```

Actors are identical for HTTP and HTTPS — SSL is handled transparently
by the protocol layer.
"""
