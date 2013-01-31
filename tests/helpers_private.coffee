
describe "Helpers (private)", ->

  describe "PassKitError", ->
    it "should be an instance of Error", ->
      err = new passkit.private.PassKitError
      err.should.be.instanceof(Error)

    it "should have message given one was provided", ->
      err = new passkit.private.PassKitError("Test message!")
      err.message.should.equal("Test message!")

  describe "generateHex", ->
    it "should be random", ->
      a = passkit.private.generateHex()
      b = passkit.private.generateHex()

      # This eliminates already exteamely low chances that hashes are same
      if a is b
        b = passkit.private.generateHex()

      a.should.not.equal(b)

    it "should return string with specified number of bytes", ->
      passkit.private.generateHex(1).length.should.equal(2)

  describe "md5", ->
    it "should return valid md5 value", ->
      passkit.private.md5("PassKit").should.equal("8e390120521cb9a29c5165dd0b49740c")

  describe "parseDigest", ->
    it "should return empty array for invalid string", ->
      s = "Invalid string"
      passkit.private.parseDigest(s).should.eql([])

    it "should return array of valid values", ->
      s = 'Digest realm="Request:9a9ds09",qop="auth",nonce="440b306b",opaque="05949be8b"'
      e = { realm: 'Request:9a9ds09', qop: 'auth', nonce: '440b306b', opaque: '05949be8b' }

      passkit.private.parseDigest(s).should.eql(e)

    it "should work with whitespace after comas", ->
      s = 'Digest realm="Request:9a9ds09", qop="auth", nonce="440b306b",opaque="05949be8b"'
      e = { realm: 'Request:9a9ds09', qop: 'auth', nonce: '440b306b', opaque: '05949be8b' }

      passkit.private.parseDigest(s).should.eql(e)

  describe "renderDigest", ->
    it "should return null if invalid Array is passed", ->
      expect(passkit.private.renderDigest({})).to.equal(null)

    it "should return valid string", ->
      p = {
        username: 'ia09sdjoa',
        realm: 'Request:9a9ds09'
      }
      e = 'Digest username="ia09sdjoa", realm="Request:9a9ds09"'

      passkit.private.renderDigest(p).should.equal(e)

  describe "sanitize", ->
    it "should stip whitespace", ->
      passkit.private.sanitize(" a b c ").should.equal("abc")

    it "should strip non alphanumeric characters", ->
      passkit.private.sanitize("#!)abc").should.equal("abc")

    it "shouldn't strip dot", ->
      passkit.private.sanitize("abc.").should.equal("abc.")

    it "shouldn't strip underscore", ->
      passkit.private.sanitize("a_b_c").should.equal("a_b_c")

    it "shouldn't strip slash", ->
      passkit.private.sanitize("a/b/c").should.equal("a/b/c")

