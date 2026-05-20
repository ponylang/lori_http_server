primitive _KeepAliveDecision
  """
  Determine whether to keep a connection alive based on HTTP version
  and the request's `Connection` header(s).

  HTTP/1.1 defaults to keep-alive; HTTP/1.0 defaults to close. The
  `Connection` header is a comma-separated list per RFC 9110 §7.6.1,
  and per RFC 9110 §5.3 multiple `Connection` field lines in the same
  message are semantically equivalent to a single comma-joined value.
  The presence of `close` or `keep-alive` as any case-insensitive
  token (with optional surrounding OWS), in any `Connection` header,
  overrides the version default. When both appear, `close` wins —
  it's the unambiguous termination signal and proxies often add
  `close` to a request that originally carried `keep-alive`.
  """

  fun apply(version: Version, headers: Headers box): Bool =>
    // Scan every `Connection` header entry as a comma-separated list.
    // Multiple entries are folded by concatenation (RFC 9110 §5.3).
    // Reuses _AcceptParser's tokenizer for OWS-trimming and comma
    // splitting; its quoted-string awareness is harmless here since
    // the Connection grammar has no quoted strings.
    var saw_keep_alive: Bool = false
    for hdr in headers.values() do
      if hdr.name == "connection" then
        for raw in _AcceptParser._split_on_comma(hdr.value).values() do
          let token: String val =
            _AcceptParser._trim_whitespace(raw).lower()
          if token == "close" then return false end
          if token == "keep-alive" then saw_keep_alive = true end
        end
      end
    end
    if saw_keep_alive then return true end
    // Default: HTTP/1.1 keeps alive, HTTP/1.0 does not
    version is HTTP11
