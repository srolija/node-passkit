
describe "Passes", ->

  describe "getPass", ->
    it "should return error when template name is missing", (done) ->
      passkit.getPass '', '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error when serial number is missing", (done) ->
      passkit.getPass 'test', '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Pass serial number is required!"))
        done()

    it "should return error when template name is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/pass/get/template/invalid/serial/100000000001/').reply(200, "{\"success\":true,\"serialNumber\":\"100000000001\",\"templateName\":\"invalid\",\"uniqueID\":null,\"templateLastUpdated\":null,\"totalPasses\":0,\"passRecords\":[]}")

      passkit.getPass 'invalid', '100000000001', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name or serial number is invalid!"))
        done()

    it "should return error when serial number is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/pass/get/template/test/serial/0/').reply(200, "{\"success\":true,\"serialNumber\":\"0\",\"templateName\":\"invalid\",\"uniqueID\":null,\"templateLastUpdated\":null,\"totalPasses\":0,\"passRecords\":[]}")

      passkit.getPass 'test', '0', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name or serial number is invalid!"))
        done()

    it "should return pass infotmation when everything is fine", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/pass/get/template/test/serial/100000000001/').reply(200, "{\"success\":true,\"serialNumber\":\"100000000001\",\"templateName\":\"test\",\"uniqueID\":\"uNiqUeIdEnT\",\"templateLastUpdated\":\"2013-01-29T19:42:54+00:00\",\"totalPasses\":1,\"passRecords\":{\"pass_1\":{\"passMeta\":{\"passStatus\":\"Not Added\",\"recoveryURL\":\"https:\\/\\/r.pass.is\\/uNiqUeIdEnT\",\"issueDate\":\"2013-01-29T23:22:26+00:00\",\"lastDataChange\":\"2013-01-29T23:22:26+00:00\",\"passbookSerial\":\"pAsSbOoKSeRiAl\"},\"passData\":{\"owner\":\"Name\"}}}}")

      passkit.getPass 'test', '100000000001', (err, data) ->
        done(err)

  describe "getPassByID", ->
    it "should return error when pass ID is missing", (done) ->
      passkit.getPassByID '', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Pass ID is required!"))
        done()

    it "should return error when pass ID is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/pass/get/passId/invalid/').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.getPassByID 'invalid', (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return pass infotmation when everything is fine", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.get('/v1/pass/get/passId/uNiqUeIdEnT/').reply(200, "{\"success\":true,\"serialNumber\":\"100000000001\",\"templateName\":\"test\",\"uniqueID\":\"uNiqUeIdEnT\",\"templateLastUpdated\":\"2013-01-29T19:42:54+00:00\",\"totalPasses\":1,\"passRecords\":{\"pass_1\":{\"passMeta\":{\"passStatus\":\"Not Added\",\"recoveryURL\":\"https:\\/\\/r.pass.is\\/uNiqUeIdEnT\",\"issueDate\":\"2013-01-29T23:22:26+00:00\",\"lastDataChange\":\"2013-01-29T23:22:26+00:00\",\"passbookSerial\":\"pAsSbOoKSeRiAl\"},\"passData\":{\"owner\":\"Name\"}}}}")

      passkit.getPassByID 'uNiqUeIdEnT', (err, data) ->
        done(err)

  describe "invalidatePass", ->
    it "should return error when template name is missing", (done) ->
      passkit.invalidatePass '', '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error when serial number is missing", (done) ->
      passkit.invalidatePass 'test', '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Pass serial number is required!"))
        done()

    it "should return error when template name is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/invalidate/template/invalid/serial/100000000001/', 'owner=Mickey&removeBarcode=true&removeLocations=true&removeRelevantDate=true').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.invalidatePass 'invalid', '100000000001', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return error when serial number is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/invalidate/template/test/serial/0/', 'owner=Mickey&removeBarcode=true&removeLocations=true&removeRelevantDate=true').reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.invalidatePass 'test', '0', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return data when everything is fine", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/invalidate/template/test/serial/100000000001/', "owner=Mickey&removeBarcode=true&removeLocations=true&removeRelevantDate=true").reply(200, "{\"success\":true,\"device_ids\":\"no registered devices\",\"passes\":1}")

      passkit.invalidatePass 'test', '100000000001', {owner: 'Mickey'}, (err, data) ->
        done(err)

    it "should return error if already invalidated", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/invalidate/template/test/serial/100000000001/', "owner=Mickey&removeBarcode=true&removeLocations=true&removeRelevantDate=true").reply(400, "{\"error\":\"Serial '100000000001' for template 'test' has already been invalidated\"}")

      passkit.invalidatePass 'test', '100000000001', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Serial '100000000001' for template 'test' has already been invalidated"))
        done()

  describe "issuePass", ->
    it "should return error when template name is missing", (done) ->
      passkit.issuePass '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error when template name is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/issue/template/invalid/', '{}').reply(200, "{\"error\":\"Template not found\"}")

      passkit.issuePass 'invalid', {}, (err, data) ->
        err.should.be.an.instanceof(passkit.private.PassKitError)
        done()

    it "should return new pass data if creation successful", (done) ->
      if not SERVER or not TOTAL
        scope = nock('https://api.passkit.com:443')
        scope.post('/v1/pass/issue/template/test/', "{}").reply(200, "{\"success\":true,\"serial\":\"2473921700897886\",\"url\":\"https:\\/\\/r.pass.is\\/crHltuhxxg3f\",\"passbookSerial\":\"1xqYQik6OgiCjATina8My\"}")

      passkit.issuePass 'test', {}, (err, data) ->
        done(err)

  describe "issueMultiplePasses", ->
    it "should return error when template name is missing", (done) ->
      passkit.issueMultiplePasses '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error when there are no passes provided", (done) ->
      passkit.issueMultiplePasses 'test', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("At least one pass must be provided!"))
        done()

    it "should return error when there are more than 100 passes provided", (done) ->
      o = {}
      # Total of 101 item.
      for num in [1..101]
        o[String(num)] = num

      passkit.issueMultiplePasses 'test', o, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Too many passes provided!"))
        done()

    it "should return error when template name is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/issue/batch/template/invalid/', "{\"pass\":{}}").reply(200, "{\"error\":\"Template not found\"}")

      passkit.issueMultiplePasses 'invalid', { pass: {}}, (err, data) ->
        err.should.be.an.instanceof(passkit.private.PassKitError)
        done()

    it "should return new pass data if creation successful", (done) ->
      if not SERVER or not TOTAL
        scope = nock('https://api.passkit.com:443')
        scope.post('/v1/pass/issue/batch/template/test/', "{\"pass\":{},\"pass2\":{}}").reply(200, "{\"success\":true,\"passes\":{\"pass\":{\"serial\":\"100000000001\",\"url\":\"https:\\/\\/r.pass.is\\/rNdMhEx\"},\"pass2\":{\"serial\":\"100000000002\",\"url\":\"https:\\/\\/r.pass.is\\/rNdMhEx2\"}},\"request_time\":-0.203458}")

      passkit.issueMultiplePasses 'test', { pass: {}, pass2: {}}, (err, data) ->
        done(err)

  describe "updatePass", ->
    it "should return error when template name is missing", (done) ->
      passkit.updatePass '', '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Template name is required!"))
        done()

    it "should return error when serial number is missing", (done) ->
      passkit.updatePass 'test', '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Pass serial number is required!"))
        done()

    it "should return error when nothing is being updated", (done) ->
      passkit.updatePass 'test', '100000000001', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Nothing to update!"))
        done()

    it "should return error when template name is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/template/invalid/serial/100000000001/push', "owner=Mickey").reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.updatePass 'invalid', '100000000001', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return error when serial number is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/template/test/serial/0/push', "owner=Mickey").reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.updatePass 'test', '0', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return something when everything is fine", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/template/test/serial/100000000001/push', "owner=Mickey").reply(200, "{\"success\":true,\"device_ids\":\"no registered devices\",\"passes\":1}")

      passkit.updatePass 'test', '100000000001', {owner: 'Mickey'}, (err, data) ->
        done(err)

    it "shouldn't have push parameter if push is set to false", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/template/test/serial/100000000001/', "owner=Mickey").reply(200, "{\"success\":true,\"device_ids\":\"no registered devices\",\"passes\":1}")

      passkit.updatePass 'test', '100000000001', {owner: 'Mickey'}, (err, data) ->
        done(err)
      , false

  describe "updatePassByID", ->
    it "should return error when pass ID name is missing", (done) ->
      passkit.updatePassByID '', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Pass ID is required!"))
        done()

    it "should return error when nothing is being updated", (done) ->
      passkit.updatePassByID 'uNiqUeIdEnT', {}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Nothing to update!"))
        done()

    it "should return error pass ID is invalid", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/passid/invalid/push', "owner=Mickey").reply(404, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><title>PassKit - 404 Not Found</title><link rel=\"icon\" type=\"image/ico\" href=\"https://d321ofrgjjwiwz.cloudfront.net/favicon.ico\"><link rel=\"apple-touch-icon\" href=\"https://passkit.s3.amazonaws.com/images/3YrwmjaWGrESOM5rVjd6dKi.png\" /><style type=\"text/css\">body {font-family: 'Helvetica Neue', Helvetica-Neue, helvetica, arial, sans-serif;\nfont-size: 22px;text-align:center;padding-top:10px;color:#0477BF;} a {color:#0477BF;} {a img {border:none!important;}</style></head><body><p style=\"text-align:center;padding-top:20px;\"><img src=\"https://d1ye292yvr7tf6.cloudfront.net/images/PassKit-404.jpg\" /></p><p>Perhaps you could try our <a href=\"http://passkit.com/\" title=\"PassKit Home Page\">Home Page</a>, <a href=\"http://code.google.com/p/passkit\" title=\"PassKit Documentation\">Documentation</a> or <a href=\"https://create.passkit.com/\" title=\"PassKit Pass Designer\">Pass Designer</a></p></body></html>")

      passkit.updatePassByID 'invalid', {owner: 'Mickey'}, (err, data) ->
        err.should.eql(new passkit.private.PassKitError("Invalid pass template name or serial number!"))
        done()

    it "should return something when everything is fine", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/passid/uNiqUeIdEnT/push', "owner=Mickey").reply(200, "{\"success\":true,\"device_ids\":\"no registered devices\",\"passes\":1}")

      passkit.updatePassByID 'uNiqUeIdEnT', {owner: 'Mickey'}, (err, data) ->
        done(err)

    it "shouldn't have push parameter if push is set to false", (done) ->
      scope = nock('https://api.passkit.com:443')
      scope.post('/v1/pass/update/passid/uNiqUeIdEnT/', "owner=Mickey").reply(200, "{\"success\":true,\"device_ids\":\"no registered devices\",\"passes\":1}")

      passkit.updatePassByID 'uNiqUeIdEnT', {owner: 'Mickey'}, (err, data) ->
        done(err)
      , false
