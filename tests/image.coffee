
describe "Images", ->

  describe "getImageUsage", ->
    it "should return error when imageID is missing", (done) ->
      passkit.getImageUsage '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Image ID is required!"))
        done()

    it "should return error in case image doesn't exist", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/image/missing/').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.getImageUsage 'missing', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid image ID!"))
        done()

    it "should return image usage in case image exists", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/image/lOnGiMaGeID/').reply(200, "{\"imageID\":\"lOnGiMaGeID\",\"Background\":\"true\"}")

      passkit.getImageUsage 'lOnGiMaGeID', (err, data) ->
        data.should.equal('background')
        done()

  describe "uploadImage", ->
    it "should return error when image role is missing or invalid", (done) ->
      passkit.uploadImage 'invalid', 'tests/images/logo.png', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Role must be valid string!"))
        done()

    it "should return error when image does not exist", (done) ->
      passkit.uploadImage 'background', 'tests/images/image.png', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Image does not exit: tests/images/image.png!"))
        done()

    it "should return error when image type is invalid", (done) ->
      passkit.uploadImage 'background', 'tests/images/logo.pdf', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid file type!"))
        done()

    it "should return error when there is file reading error", (done) ->
      s = sinon.stub(require("fs"), "stat")
      s.callsArgWith(1, new Error("File reading error!"), null)

      passkit.uploadImage 'background', 'tests/images/logo.png', (err, data) ->
        err.should.eql(new Error("File reading error!"))
        s.restore()
        done()

    it "should return error when file size is too big", (done) ->
      s = sinon.stub(require("fs"), "stat")
      s.callsArgWith(1, null, {size: 1572864})

      passkit.uploadImage 'background', 'tests/images/logo.png', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Image too large (larger than 1.5MB): 1572864!"))
        s.restore()
        done()

    it "should return imageID and usage on success", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/image/add/background/', "\r\n-------00000000\r\nContent-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\nContent-Type: image/png\r\n\r\n\r\n-------00000000\r\nContent-Disposition: form-data; name=\"type\"\r\n\r\nimage/png\r\n-------00000000--").reply(200, "{\"success\":\"true\",\"imageID\":\"sOmErAnDoMhEx\",\"usage\":\"Background Image\"}")

      s = sinon.stub(require("crypto"), "randomBytes")
      s.returns(new Buffer([0,0,0,0]))

      passkit.uploadImage 'background', 'tests/images/logo_empty.png', (err, data) ->
        data.should.eql(
          imageID: "sOmErAnDoMhEx"
          usage: "Background Image"
        )
        s.restore()
        done(err)

    if SERVER and TOTAL
      it "should sucessfuly upload image to server", (done) ->
        passkit.uploadImage 'background', 'tests/images/logo.png', (err, data) ->
          done(err)
