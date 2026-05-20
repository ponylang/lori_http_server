primitive _KeepAliveDecision
  """
  Determine whether to keep a connection alive based on HTTP version
  and the Connection header value.

  HTTP/1.1 defaults to keep-alive; HTTP/1.0 defaults to close. The
  Connection header is a comma-separated list per RFC 9110 §7.6.1; the
  presence of `close` or `keep-alive` as any case-insensitive token
  (with optional surrounding OWS) overrides the version default. When
  both appear in the list, `close` wins — it's the unambiguous
  termination signal and proxies often add `close` to a request that
  originally carried `keep-alive`.
  """

  fun apply(version: Version, connection: (String | None)): Bool =>
    match connection
    | let c: String =>
      // Scan the comma-separated list for `close` or `keep-alive`
      // rather than comparing the whole value. Reuses _AcceptParser's
      // tokenizer (quoted-string-aware, OWS-trimming) so list-header
      // handling stays consistent across the codebase.
      var saw_keep_alive: Bool = false
      for raw in _AcceptParser._split_on_comma(c).values() do
        let token: String val =
          _AcceptParser._trim_whitespace(raw).lower()
        if token == "close" then return false end
        if token == "keep-alive" then saw_keep_alive = true end
      end
      if saw_keep_alive then return true end
    end
    // Default: HTTP/1.1 keeps alive, HTTP/1.0 does not
    version is HTTP11
