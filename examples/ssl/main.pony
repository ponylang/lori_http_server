"""
HTTPS server that responds to every request with "Hello, World!".

Demonstrates SSL/TLS support: creating an `SSLContext`, loading certificate
and key files, and passing the context to connection actors via `_on_accept`.
The `HTTPServer` handles SSL dispatch internally — actors are identical for
HTTP and HTTPS.

Must be run from the project root so the relative certificate paths resolve
correctly. Test with `curl -k https://localhost:8443/`.
"""
use "files"
use "ssl/net"
use http_server = "../../http_server"
use lori = "lori"
use "time"

actor Main is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _env: Env
  let _config: http_server.ServerConfig
  let _server_auth: lori.TCPServerAuth
  var _ssl_ctx: (SSLContext val | None) = None

  new create(env: Env) =>
    _env = env
    let auth = lori.TCPListenAuth(env.root)
    _server_auth = lori.TCPServerAuth(auth)
    _config = http_server.ServerConfig("localhost", "8443")
    let file_auth = FileAuth(env.root)
    try
      _ssl_ctx = recover val
        SSLContext
          .> set_authority(
            FilePath(file_auth, "assets/cert.pem"))?
          .> set_cert(
            FilePath(file_auth, "assets/cert.pem"),
            FilePath(file_auth, "assets/key.pem"))?
          .> set_client_verify(false)
          .> set_server_verify(false)
      end
      _tcp_listener = lori.TCPListener(auth, "localhost", "8443", this)
    else
      env.out.print("Unable to set up SSL context")
    end

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor =>
    _HelloServer(_server_auth, fd, _config, _ssl_ctx, None)

  fun ref _on_listening() =>
    _env.out.print("HTTPS server listening on localhost:8443")

  fun ref _on_listen_failure() =>
    _env.out.print("Failed to start server")

  fun ref _on_closed() =>
    _env.out.print("Server closed")

actor _HelloServer is http_server.HTTPServerActor
  var _http: http_server.HTTPServer = http_server.HTTPServer.none()

  new create(
    auth: lori.TCPServerAuth,
    fd: U32,
    config: http_server.ServerConfig,
    ssl_ctx: (SSLContext val | None),
    timers: (Timers | None))
  =>
    _http = http_server.HTTPServer(auth, fd, ssl_ctx, this,
      config, timers)

  fun ref _http_connection(): http_server.HTTPServer => _http

  fun ref request_complete(responder: http_server.Responder) =>
    let resp_body: String val = "Hello, World!"
    let response = http_server.ResponseBuilder(http_server.StatusOK)
      .add_header("Content-Type", "text/plain")
      .add_header("Content-Length", resp_body.size().string())
      .finish_headers()
      .add_chunk(resp_body)
      .build()
    responder.respond(response)
