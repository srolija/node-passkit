
describe "Templates", ->

  describe "getTemplateFields", ->
    it "should return error when template name is missing", (done) ->
      passkit.getTemplateFields '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error in case template doesn't exist", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/template/missing/fieldnames/').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.getTemplateFields 'missing', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid template name!"))
        done()

    it "should return list of fields for specific template", (done) ->
      if not SERVER
        scope = nock('https://api.passkit.com:443')
        scope.get('/v1/template/test/fieldnames/').reply(200, "{\"success\":true,\"test\":{\"stripImage\":{\"type\":\"imageID\"},\"iconImage\":{\"type\":\"imageID\"},\"logoImage\":{\"type\":\"imageID\"},\"logoText\":{\"type\":\"text\"},\"owner\":{\"type\":\"text\",\"default\":\"Name\"}},\"lastUpdated\":\"2013-01-27T23:03:24+00:00\"}")

      passkit.getTemplateFields 'test', (err, data) ->
        data.owner.should.not.be.undefined
        done(err)

  describe "getTemplates", ->
    it "should return empty list when there are no templates", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/template/list/').reply(200, "{\"error\":\"No Templates Found\"}")

      passkit.getTemplates (err, data) ->
        err.should.be.an.instanceof(passkit.private.PassKitError)
        done()

    it "should return list of templates", (done) ->
      if not SERVER
        scope = nock('https://api.passkit.com:443')
        scope.get('/v1/template/list/').reply(200, "{\"success\":true,\"templates\":[\"test\"]}")

      passkit.getTemplates (err, data) ->
        expect(data.length).not.to.be.below(1)
        done(err)

  describe "resetTemplate", ->
    it "should return error when template name is missing", (done) ->
      passkit.resetTemplate '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error in case template doesn't exist", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/template/missing/reset/').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.resetTemplate 'missing', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid template name!"))
        done()

    it "shouldn have `push` parameter when push is enabled", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/template/test/reset/push').reply(200, "{\"success\":true,\"devices\":true}")

      passkit.resetTemplate 'test', (err, data) ->
        done(err)

      , true

    it "should return dictionary on success", (done) ->
      if not SERVER or not TOTAL
        scope = nock('https://api.passkit.com:443')
        scope.get('/v1/template/test/reset/').reply(200, "{\"success\":true,\"devices\":true}")

      passkit.resetTemplate 'test', (err, data) ->
        done(err)
      , false

   describe "updateTemplate", ->
    it "should return error when template name is missing", (done) ->
      passkit.updateTemplate '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error in case template doesn't exist", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/template/update/missing/').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.updateTemplate 'missing', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid template name!"))
        done()

    it "should have `push` parameter when push is enabled", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/template/update/test/push').reply(200, "{\"success\":true,\"devices\":true}")

      passkit.updateTemplate 'test', {}, (err, data) ->
        done(err)

      , true

    it "should have `reset` parameter when reset is enabled", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/template/update/test/reset/').reply(200, "{\"success\":true,\"devices\":true}")

      passkit.updateTemplate 'test', {}, (err, data) ->
        done(err)

      , false, true

    it "should return dictionary on success", (done) ->
      if not SERVER
        scope = nock('https://api.passkit.com:443')
        scope.post('/v1/template/update/test/', "owner_label=Name").reply(200, "{\"success\":true}")

      passkit.updateTemplate 'test', {"owner_label": "Name"}, (err, data) ->
        done(err)
