
describe "PassKit", ->

  describe "initialization", ->
    it "should throw error when username is missing", ->
      fn = ->
        passkit_src("", "PASS")
      expect(fn).to.throw(/Account ID is required/)

    it "should throw error when secret is missing", ->
      fn = ->
         passkit_src("USER", "")
      expect(fn).to.throw(/Account Secret is required/)

    it "should return object with funcitons when data is fine", ->
      fn = ->
        passkit_src("USER", "PASS")
      expect(fn).not.to.throw()

  describe "request", ->
    it "should first time do the authenticaion", (done) ->

      if not SERVER
        scope = nock('https://api.passkit.com:443')
        scope.get('/v1/authenticate/').reply(401, "{\"error\":\"Missing Credentials\"}", { 'www-authenticate': 'Digest realm="long_string",qop="auth",nonce="some_hex",opaque="long_hex"' })
        scope.get('/v1/authenticate/').reply(200, "{\"success\":true}")

      options =
        path: "/authenticate/"

      s = sinon.spy(https, "request")
      passkit.request (err, data) ->
        expect(s.firstCall.args[0].headers).to.be.undefined
        expect(s.secondCall.args[0].headers["Authorization"]).not.to.be.undefined
        s.restore()
        done(err)

      , options


    it "should second time directly call route", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/route').reply(200, "{\"success\":true}")

      options =
        path: "/route"

      s = sinon.spy(https, "request")
      passkit.request (err, data) ->
        s.callCount.should.equal(1)
        s.restore()
        done(err)

      , options

    it "should request authentication data and retry request on 401 Error", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/route').reply(401, "{\"error\":\"Authentication Error or Timeout\"}")
      scope.get('/v1/authenticate/').reply(401, "{\"error\":\"Missing Credentials\"}", { 'www-authenticate': 'Digest realm="long_string",qop="auth",nonce="some_hex",opaque="long_hex"' })
      scope.get('/v1/route').reply(200, "{\"success\":true}")

      options =
        path: "/route"

      s = sinon.spy(https, "request")
      passkit.request (err, data) ->
        expect(s.secondCall.args[0].path).to.equal("/v1/authenticate/")
        expect(s.lastCall.args[0].headers["Authorization"]).not.to.be.undefined
        s.restore()
        done(err)

      , options


    it "should send proper headers when there is body", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/route Text').reply(200, "{\"success\":true}")

      options =
        method: "POST"
        path: "/route"

      body = "Text"

      s = sinon.spy(https, "request")
      passkit.request (err, data) ->
        # Must be lastCall because previous test will invalidate authentication
        # when hiting API instead of mocks.
        s.lastCall.args[0].headers["Content-Length"].should.not.equal(0)
        s.restore()
        done(err)

      , options, body

    it "should return dictionary without success key when response is JSON", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/route').reply(200, "{\"success\":true, \"value\":5}")

      options =
        path: "/route"

      passkit.request (err, data) ->
        data.json.should.eql({value: 5})
        done(err)

      , options

    it "should return error when response is not JSON", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/route').reply(200, "OK!")

      options =
        path: "/route"

      passkit.request (err, data) ->
        err.should.be.instanceof(passkit.private.PassKitError)
        done()

      , options

  describe "testConnection", ->
    it "shouldn't return error if username and password are valid", (done) ->

      if not SERVER
        scope = nock('https://api.passkit.com:443')
        scope.get('/v1/authenticate/').reply(200, "{\"success\":true}")

      passkit.testConnection (err, data) ->
        done(err)
