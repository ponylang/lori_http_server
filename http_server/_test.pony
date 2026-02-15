use "pony_test"
use "pony_check"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    // Method tests
    test(Property1UnitTest[String val](_PropertyValidMethodParsesCorrectly))
    test(Property1UnitTest[String val](_PropertyInvalidMethodReturnsNone))
    test(Property1UnitTest[(String val, Bool)](
      _PropertyMethodParseBoundary))

    // Headers tests
    test(Property1UnitTest[(String val, String val)](
      _PropertyHeadersCaseInsensitive))
    test(Property1UnitTest[(String val, String val, String val)](
      _PropertyHeadersSetReplaces))
    test(Property1UnitTest[(String val, String val, String val)](
      _PropertyHeadersAddPreserves))

    // Response serializer tests
    test(Property1UnitTest[_ResponseInput](
      _PropertyResponseWireFormat))
    test(_TestResponseSerializerKnownGood)
