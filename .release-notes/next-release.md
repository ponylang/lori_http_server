## Added cookie parsing and serialization

Stallion now provides built-in cookie support in two directions: reading cookies from requests and building `Set-Cookie` response headers.

Cookies are automatically parsed from `Cookie` request headers and available on the `Request` object. Use `request'.cookies.get("name")` to look up a cookie by name, or `request'.cookies.values()` to iterate over all parsed cookies:

```pony
fun ref on_request_complete(request': stallion.Request val,
  responder: stallion.Responder)
=>
  match request'.cookies.get("session")
  | let token: String val =>
    // Use the session token
  end
```

For direct parsing outside the request lifecycle, `ParseCookies` accepts a raw `Cookie` header value string or a `Headers val` collection.

To build `Set-Cookie` response headers, use `SetCookieBuilder`. It defaults to `Secure`, `HttpOnly`, and `SameSite=Lax` — override explicitly when needed:

```pony
match stallion.SetCookieBuilder("session", token)
  .with_path("/")
  .with_max_age(3600)
  .build()
| let sc: stallion.SetCookie val =>
  // Add to response: .add_header("Set-Cookie", sc.header_value())
| let err: stallion.SetCookieBuildError =>
  // Handle validation error
end
```

The builder validates cookie names (RFC 2616 token), values (RFC 6265 cookie-octets), and path/domain attributes (no CTLs or semicolons), enforces `__Host-` and `__Secure-` prefix rules, and checks `SameSite=None` + `Secure` consistency.

New types: `Header`, `RequestCookie`, `RequestCookies`, `ParseCookies`, `SetCookie`, `SetCookieBuilder`, `SetCookieBuildError`, `SameSite` (`SameSiteStrict`, `SameSiteLax`, `SameSiteNone`).

## Changed Headers.values() to yield Header val instead of tuples

`Headers.values()` now yields `Header val` objects instead of `(String, String)` tuples. Code that destructures header values needs to change from field access on tuples to field access on the `Header` class:

Before:

```pony
for (name, value) in headers.values() do
  env.out.print(name + ": " + value)
end
```

After:

```pony
for hdr in headers.values() do
  env.out.print(hdr.name + ": " + hdr.value)
end
```
## Add content negotiation

Stallion now provides opt-in content negotiation for selecting a response content type based on the client's `Accept` header (RFC 7231 §5.3.2). This is useful for endpoints that support multiple formats — most endpoints serve a single content type and don't need this.

Use `ContentNegotiation.from_request()` to negotiate against a list of supported media types:

```pony
let supported = [as stallion.MediaType val:
  stallion.MediaType("application", "json")
  stallion.MediaType("text", "plain")
]
match stallion.ContentNegotiation.from_request(request', supported)
| let mt: stallion.MediaType val =>
  // Respond with the negotiated type (mt.string() gives "application/json" etc.)
| stallion.NoAcceptableType =>
  // Respond with 406 Not Acceptable
end
```

The algorithm follows RFC 7231 precedence rules: exact types beat wildcards, higher quality values win, ties go to the first type in the server's supported list, and `q=0` explicitly excludes a type. An absent `Accept` header means "accept anything" — the first supported type is returned.

`ContentNegotiation.apply()` accepts a raw Accept header value string directly, for testing or when you already have the header value.

New types: `MediaType`, `NoAcceptableType`, `ContentNegotiationResult`, `ContentNegotiation`.

