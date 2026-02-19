# Examples

Each subdirectory is a self-contained Pony program demonstrating a different part of the http_server library. Ordered from simplest to most involved.

## [basic](basic/)

Responds to every request with "Hello, World!". Demonstrates the core API: the listener actor implements `lori.TCPListenerActor` directly, creating `HTTPServerActor` instances via `HTTPServer`, `Request`, `Responder`, and `ServerConfig`. Also shows query parameter extraction from the pre-parsed URI. Start here if you're new to the library.

## [builder](builder/)

Constructs responses dynamically using `ResponseBuilder`. Demonstrates the builder's typed state machine that guides the caller through status line, headers, then body. Similar to basic but focused on the response construction API.

## [ssl](ssl/)

HTTPS server using SSL/TLS. Demonstrates creating an `SSLContext`, loading certificate and key files, and passing the context to connection actors via `_on_accept`. The `HTTPServer` handles SSL dispatch internally — the actor code is identical for HTTP and HTTPS.

## [streaming](streaming/)

Streams responses using chunked transfer encoding. Demonstrates `start_chunked_response()`, `send_chunk()`, and `finish_response()` on `Responder`. Each request receives three chunks before the response is finalized.
