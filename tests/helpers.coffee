
describe "Helpers (public)", ->

  describe "parsePassURL", ->
    it "should return error for invalid string", ->
      fn = ->
        passkit.helpers.parsePassURL('not url')
      expect(fn).to.throw(passkit.PassKitError)

    it "should return unique ID for https url", ->
      id = ''
      fn = ->
        id = passkit.helpers.parsePassURL('https://r.pass.is/pAsSuNiqUeID')
      expect(fn).not.to.throw()
      id.should.equal('pAsSuNiqUeID')

    it "should return unique ID for http url", ->
      id = ''
      fn = ->
        id = passkit.helpers.parsePassURL('http://r.pass.is/url/pAsSuNiqUeID')
      expect(fn).not.to.throw()
      id.should.equal('pAsSuNiqUeID')

    it "should return unique ID for url with trailing slash", ->
      id = ''
      fn = ->
        id = passkit.helpers.parsePassURL('https://r.pass.is/url/pAsSuNiqUeID/')
      expect(fn).not.to.throw()
      id.should.equal('pAsSuNiqUeID')

  describe "supportsPassbook", ->
    context "iPhone or iPod", ->
      it "should work on iOS 6 on iPhone", ->
        userAgents = [
          # Safari on iOS
          "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A523 Safari/8536.25",
          # Chrome on iOS
          "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0_1 like Mac OS X; en-us) AppleWebKit/536.26 (KHTML, like Gecko) CriOS/23.0.1271.100 Mobile/10A523 Safari/8536.25"
        ]
        for agent in userAgents
          passkit.helpers.supportsPassbook(agent).should.be.true

      it "should work on iOS 6 on iPod", ->
        userAgent = "Mozilla/5.0 (iPod; CPU iPhone OS 6_0_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A523 Safari/8536.25"
        passkit.helpers.supportsPassbook(userAgent).should.be.true

      it "shouldn't work on iOS 5 or lower", ->
        userAgents = [
          # Safari on iOS
          "Mozilla/5.0 (iPhone; CPU iPhone OS 5_1_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10A5376e",
          "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7",
        ]
        for agent in userAgents
          passkit.helpers.supportsPassbook(agent).should.be.false

    context "Mac", ->
      it "should work on Safari on OS X 10.8.2 and newer", ->
        userAgents = [
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
        ]
        passkit.helpers.supportsPassbook(userAgents).should.be.true

      it "should not work on Safari on OS X odler than 10.8.2", ->
        userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
        passkit.helpers.supportsPassbook(userAgent).should.be.false

      it "shouldn't work on Chrome on OS X 10.8.2 and newer", ->
        userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"
        passkit.helpers.supportsPassbook(userAgent).should.be.false
