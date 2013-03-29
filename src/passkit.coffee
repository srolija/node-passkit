# *Author: Sergej Jakovljev*

# **[PassKit](http://www.passkit.com/)** is a simple service used for using
# Passbook passes in web and other applications. 
# This library makes using PassKit API simple by removing overhead of 
# authenticating using Digest authentication and by implementing all of the 
# available API endpoints as functions. You can download this library from 
# [Github](https://github.com/srolija/node-passkit).
#
# Be sure to check at the end of this document how each function is mapped to 
# module exports in order to avoid any confusion regarding missing functions.
#
# ## Important
# For almost all functions in PassKit class `callback` parameter is required, it
# should be function that receives two parameters. The first parameter is 
# `error` which will be instance of PassKitError with message containing error 
# from server if error occurred otherwise it will be `null`. Second parameter 
# will have data API returned if there was no error.
#
# There is limit of 1 push request to all passes within one template to every 10 
# minutes.
#
# Example:
#
#     // Import library as passkit
#     passkit.testConnection(function(err, data){
#       if (err) {
#         // Handle error case
#         console.error(err);
#       } else {
#         // Do something with data 
#         // NOTICE: testConnection doesn't return anything
#         console.log("API works!");
#       }
#     });
#

# ## Field types
#  - **static**: these cannot be changed via pass methods, only by template methods 
# such as template update.
#  - **dynamic**: these can be changed via pass methods such as pass update as well 
# as template methods.
#  - **user**: these are dynamic fields that can be filled in by the user when they 
# go to the pass URL to download it. 
#
crypto = require("crypto")
fs = require("fs")
querystring = require("querystring")
https = require("https")
mime = require("mime")

HOST = "api.passkit.com"
API = "/v1"
PORT = 443





# # Helpers (private)
# Private functions that are used by PassKit class. They are not meant to be 
# used outside the library itself but if one really wants they can be accessed
# under `.private` library attribute.

# ### generateHex(\[length\])
# Returns string with random hexadecimal characters made out of `length` bytes.
# If no `length` attribute is passed it will be set to 6.  
# Returned string will be long twice the number of bytes.
#
#     generateHex();
#     // => "36e44ae142db"
#     generateHex(12);
#     // => "c6ff4246b7be31f19580daa6"
#
#
generateHex = (length=6) ->
  crypto.randomBytes(length).toString("hex")

# ### md5(value)
# Shortcut for creating md5 hash synchronously from given `value` and returning
# it as a string.
#
#     md5("PassKit");
#     // => "8e390120521cb9a29c5165dd0b49740c
#
md5 = (value) ->
  crypto.createHash("md5").update(value).digest("hex")

# ### PassKitError(\[message\])
# Custom `Error` class for this library to make understanding where error came
# from more easy, `message` parameter is optional and it will serve as error 
# message.
#
#     throw new PassKitError('Wrong username!');
#     // => PassKitError: Wrong username!
#
PassKitError = (message='') ->
  Error.call(this)
  Error.captureStackTrace(this, arguments.callee)
  @message = message
  @name = "PassKitError"

PassKitError.prototype.__proto__ = Error.prototype

# ### parseDigest(header)
# Parse `header` which is string data from www-authenticate header and return it
# as an array of key-value pairs.
#
# It works by removing "Digest" from beginning of `header` then it splits the 
# rest by commas and splits each line into key and value pair.
#
#     var s = 'Digest realm="Request:9a9ds09",qop="auth",' +
#         'nonce="440b306b",opaque="05949be8b"';
#
#     parseDigest(s);
#     // => [ realm: 'Request:9a9ds09',
#     //      qop: 'auth',
#     //      nonce: '440b306b',
#     //      opaque: '05949be8b' ]
#
parseDigest = (header) ->
  parameters = []

  headerArray = header.substring(6).split(/,\s*/)
  if headerArray.length > 1
    for parameter in headerArray
      pair = parameter.split("=")
      key = pair[0].replace(/\s*/g, "")
      value = pair[1].replace(/"/g, "")
      parameters[key] = value

  return parameters

# ### renderDigest(parameters)
# Converts object with `parameters` to formated string.
#
# It will create string starting with "Digest " and add each of key-value 
# parameters to it. At the end it removes last two characters (", ") that are 
# unnecessary because at that point we have already added all parameters.
#
# In case that parameters is empty `null` will be returned.
#
#     var params = { 
#       username: 'ia09sdjoa',
#       realm: 'Request:9a9ds09'
#     };
#
#     renderDigest(params);
#     // => 'Digest username="ia09sdjoa", realm="Request:9a9ds09"'
#
renderDigest = (parameters) ->
  header = "Digest "

  for key in Object.keys(parameters)
    header += "#{key}=\"#{parameters[key]}\", "

  if header is "Digest "
    return null

  return header.substring(0, header.length - 2)


# ### sanitize(value)
# Strips non alpha-numerics except _ (underline), . (dot) and / (slash) from 
# `value`.  
# This way we can be sure that values like `username`, `secret` and generaly
# unique ID-s that we are going to use have no invalid characters (for example 
# accidental whitespace).
#
#     sanitize("$  ed8808.d5e.1f6d289dc16_0b7b");
#     // => "ed8808.d5e.1f6d289dc16_0b7b"
#
sanitize = (value) ->
  value.replace(/[^\w\.\/]/gi, "")





# # Helpers (public)
# Helpers that may not be used by PassKit class but could be useful for using 
# along this library. They are available under `.helpers` attribute of library. 

# ### parsePassURL(url)
# Takes pass recovery or download `url` and returns unique pass ID. Pass ID can
# be used with method names that contain `ByID` at the end instead of serial and 
# template name pair.  
# Typical use case would be when you issue pass and you want to find out pass ID
# without querying server for newly created pass.
#
# In case of invalid `url` it will throw `PassKitError`!
#
# Example:
#
#     parsePassURL("https://r.pass.is/pAsSuNiqUeID");
#     // => "pAsSuNiqUeID"
#
parsePassURL = (url) ->
  if url[url.length-1] is '/'
    url = url.substring(0, url.length - 1)

  if not /http(s)*:\/\/(.+)/i.test(url)
    throw new PassKitError("Invalid string!")

  return /http(s)*:\/\/(.+)\/(.*)/i.exec(url)[3]

# ### supportsPassbook(userAgent)
# Returns `true` if `userAgent` supports Passbook.
# ATM only supported browsers are Safari on OS X 10.8.2+ and Safari on iOS 6. 
# You will be most likely calling this function with 
# `request.headers['user-agent']` as a parameter.
# 
#     // Mobile Safari on iOS 6.0
#     var UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 ...";
#     supportsPassbook(UA);
#     // => true
#     
#     // Safari on OS X 10.7.3
#     var UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3 ..";
#     supportsPassbook(UA);
#     // => false
#
#     // Safari on OS X 10.8.2
#     var UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2 ..";
#     supportsPassbook(UA);
#     // => true
#
supportsPassbook = (userAgent) ->

  # Check for most popular browsers, if it is Safari/Webkit based and it is not 
  # Chrome (Chromium/Chrome) then it is most likely either Safari on OS X or 
  # Safari on iOS (other browsers on iOS like Chrome are in most cases just 
  # warper over Mobile Safari and Mobile Safari on iOS 6+ supports passes so 
  # most browsers on iPhone should by default also support them).
  if /Safari/gi.test(userAgent) and not /Chrom/gi.test(userAgent)

    return true if /iPhone; CPU iPhone OS 6/gi.test(userAgent)
    return true if /iPod; CPU iPhone OS 6/gi.test(userAgent)

    return true if /Mac OS X 10_8_[2-9]/gi.test(userAgent)
    return true if /Mac OS X 10_9_[0-9]/gi.test(userAgent)

  return false    





# # PassKit class (public)
# ### PassKit(account, secret)
# This is what gets called on when library is required.
#
# It takes two parameters: `account` and `secret` which are used for 
# authentication with server. If either of them are missing `PassKitError` will 
# be thrown.
PassKit = (account, secret) ->
  
  if not sanitize(account)
    throw new PassKitError("Account ID is required.")

  if not sanitize(secret)
    throw new PassKitError("Account Secret is required.")

  # Digest authentication values, this is created here in order to be shared 
  # between multiple (parallel) requests because we want to make as little 
  # requests to the API as possible, best way to do it is by requesting new 
  # digest data only when it is changed. Either every specified time interval or
  # when Error 401 is returned (later more about exact process).
  digest =
    counter: 0
    HA1: null
    nonce: null
    opaque: null
    qop: null
    realm: null
    time: new Date(0)
    
  # ## Base functions

  # ### request(callback, \[options\], \[body\], \[stringify\])
  # This function is used as request handler for all the other functions.
  # `options` is object with values which are passed to the `https.request`
  # and `body` is content that is sent in body of request (in case of `POST` or 
  # `PUT` method). `stringify` dictates whether `body` content should be encoded
  # as a query string or not.
  #
  # #### Implementation
  # In order to communicate with PassKit API we need to use Digest access 
  # authentication which is not supported by core libraries nor any `npm` 
  # package (there are some but they are built for server side, we need client 
  # -- https.request that supports it). Reasons why there isn't support yet and 
  # most likely will never be can be found here: 
  # [https://github.com/joyent/node/issues/4426](https://github.com/joyent/node/issues/4426).
  #
  # This implementation follows implementation example that can be found on
  # [Wikipedia - Digest access authentication](http://en.wikipedia.org/wiki/Digest_access_authentication).
  # This implementation is specific to the current version of authentication
  # that PassKit API is using `qop="auth"` if `qop` changes some changes will be 
  # required.
  request = (callback, options, body=null, stringify=false) ->

    # This will be used to clone option object if we need it in its original 
    # form for reauthorization and retrial request if we get 401: 
    # Authentication error.
    #
    # Clone function credits (*author: ConroyP*): 
    # [http://stackoverflow.com/a/122190](http://stackoverflow.com/a/122190)
    cloneObject = (obj) ->
      return obj  if not obj? or typeof (obj) isnt "object"
      temp = obj.constructor()
      for key of obj
        temp[key] = cloneObject(obj[key])
      temp

    # Copy options (call function will modify it and this way we preserve 
    # original data).
    options_tmp = cloneObject(options)
    # Temponary body content must be outside call function scope because we need
    # it to end request.
    body_tmp = ''

    call = (retry=false) ->
      options.host = HOST unless options.host
      options.method = "GET" unless options.method
      options.path = API + options.path
      options.port = PORT unless options.port

      HA2 = md5("#{options.method}:#{options.path}")
      nonceCount = ++digest.counter
      nonceClient = generateHex()
      response = md5("#{digest.HA1}:#{digest.nonce}:#{nonceCount}:#{nonceClient}:auth:#{HA2}")

      # If we haven't passed any other headers we should initialize headers as
      # an empty object.
      options.headers = {} unless options.headers
      options.headers["Authorization"] = renderDigest(
        username: account
        realm: digest.realm
        nonce: digest.nonce
        uri: options.path
        response: response
        opaque: digest.opaque
        qop: digest.qop
        nc: nonceCount
        cnonce: nonceClient
      )

      # If we are using POST or PUT method we need to specify body length along
      # with body data we are sending. This won't check if you are using POST
      # or PUT method but if body is present (if it is, it is assumed that data
      # is being sent).
      if body
        if stringify
          body_tmp = querystring.stringify(body) 
        else
          # If we aren't stringifying it then it won't be changed for retrial
          # in case of 401 so there is no need to copy it. 
          body_tmp = body
        # Content-Length header requires lenght in bytes not characters.
        options.headers["Content-Length"] = Buffer.byteLength(body_tmp, 'utf8')
        # Default content type, it will be overridden on multi-part POST.
        options.headers["Content-Type"] = "application/x-www-form-urlencoded" unless options.headers["Content-Type"]

      # Finally we can create request.
      https.request(options, (res) ->
        res.setEncoding("utf-8")

        response =
          statusCode: res.statusCode
          headers: res.headers
          body: ""

        res.on("data", (chunk) -> response.body += chunk)
        res.on("end", ->
          # On first 401: Authentication error retry authentication and resend
          # request.
          if not retry and response.statusCode is 401 
            # Make backup options new options for retrying request. This will
            # move just reference but it is fine since this is going to be
            # called only once.
            options = options_tmp
            auth(true)
            return

          # Try convert received JSON body to Javascript object, fall-back to 
          # object with `error` field that contains normal body. This is because
          # API will return JSON for every successful request.
          try
            response.json = JSON.parse(response.body)
          catch error
            response.json = 
              error: response.body

          # Handle error the Node way, by returning `err`, `data` pair, instead 
          # of just returning response object.
          if response.statusCode is 200 and response.json.success
            err =  null
            delete response.json.success
          else 
            err = new PassKitError(response.json.error)

          callback(err, response);
        )
      ).end(body_tmp)
    
    auth = (retry=false) ->
      newTime = new Date()

      # Always get digest header from route that we are sure that provides it 
      # `/v1/authenticate`.
      authOpts =
        host: HOST
        method: "GET"
        path: API + "/authenticate/"
        port: PORT

      https.get(authOpts, (res) ->
        res.setEncoding("utf-8")
        res.on("end", ->
          # Authentication header will be specified we just need to parse it and
          # save data for future requests.
          responseParams = parseDigest(res.headers["www-authenticate"])

          digest.realm = responseParams.realm
          digest.nonce = responseParams.nonce
          digest.opaque = responseParams.opaque
          digest.qop = responseParams.qop

          # Generate hashes that are used in response and create new client 
          # nonce for this request and sets time when last update to digest data
          # was made.
          digest.HA1 = md5("#{account}:#{digest.realm}:#{secret}")
          digest.time = newTime
          call(retry)
        )
      )

    # We update authentication data every 100 seconds (in milliseconds), because
    # server changes realm each 120 seconds and each key is valid while the next
    # one is being served. Making it valid to use key for little bit less than 
    # 240 seconds from moment of issuing. In case key is changed before it will
    # return 401 Authentication error and request will be retried with new key.
    if new Date - digest.time < (100000)
      call()
    else
      auth()


  # ### testConnection(callback)
  # Test if entered user credentials are valid and everything is working. In 
  # case of error `error` will be returned, otherwise nothing will be returned 
  # (just test whether there was error).
  testConnection = (callback) ->
    opt =
      path: "/authenticate/"

    request((err, response) ->
      callback(err, null)
    , opt)





  # ## Template functions

  # ### getTemplateFields(name, callback, \[all\]) 
  # Returns dynamic fields and format for each for specified template `name`, if
  # parameter `all` is set to `true` it will fetch both static and dynamic 
  # fields.
  #
  # Example return data:
  #
  #     { 
  #       stripImage: { type: 'imageID' },
  #       iconImage: { type: 'imageID' },
  #       logoImage: { type: 'imageID' },
  #       logoText: { type: 'text' },
  #       owner: { type: 'text', default: 'Name' } 
  #     }
  #
  getTemplateFields = (name, callback, all=false) ->
    if not sanitize(name)
      callback(new PassKitError("Template name is required!"), null)
      return

    opt =
      path: "/template/#{encodeURIComponent(name)}/fieldnames/"
    
    opt.path += "full" if all

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid template name!"
        callback(err, null)
      else
        callback(err, response.json[name])
    , opt)

  # ### getTemplates(callback) 
  # Returns array of templates that exist for current `username`.
  #
  # Example return data:
  #
  #     ['test', 'cool_template', 'carneval_tickets']
  #
  getTemplates = (callback) ->
    opt = 
      path: "/template/list/"

    request((err, response) ->
      if err
        callback(err, null)
      else
        callback(err, response.json.templates)
    , opt)

  # ### resetTemplate(name, callback, \[push\]) 
  # It will reset all passes within template `name` to default values 
  # (except user-defined fields). If `push` parameter is set to `true` it will 
  # push changes to all passes, this is enabled by default.
  #
  # **This is function you shouldn't be using except if you really know what are 
  # you doing.**
  #
  # Example return data:
  #
  #     { devices: true }
  #
  resetTemplate = (name, callback, push=false) ->
    if not sanitize(name)
      callback(new PassKitError("Template name is required!"), null)
      return

    opt = 
      path: "/template/#{encodeURIComponent(name)}/reset/"

    opt.path += "push" if push

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid template name!"
        # Cover temporary issue on API (when reset is sent without prior update 
        # 500: Internal server error is returned).
        if response.statusCode is 503
          err.message = "Template must be updated prior reset!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt)

  # ### updateTemplate(name, fields, callback, \[push\], \[reset\]) 
  # Update template `name` with `fields` object. If `push` parameter is 
  # set to `true` changes will be pushed to all passes, if `reset` is set to 
  # `true` all fields except user-entered will be reseted to their default 
  # values.  
  # In case of success `{}` will be returned.
  updateTemplate = (name, fields, callback, push=false, reset=false) ->
    if not sanitize(name)
      callback(new PassKitError("Template name is required!"), null)
      return

    opt = 
      method: "POST"
      path: "/template/update/#{encodeURIComponent(name)}/"
    
    opt.path += "reset/" if reset
    opt.path += "push" if push

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid template name!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, fields, true)





  # ## Image functions

  # ### getImageUsage(imageID, callback) 
  # Returns image usage string for given `imageID`. Return value will be one 
  # of the following:
  #
  #     'background', 'footer', 'logo', 'icon', 'strip', 'thumbnail'
  #
  getImageUsage = (imageID, callback)  ->
    if not sanitize(imageID)
      callback(new PassKitError("Image ID is required!"), null)
      return

    opt =
      method: "GET"
      path: "/image/#{imageID}/"

    request((err, response) ->
      # Return appropriate string name for given image.
      if response.statusCode is 200
        callback(0, "background") if response.json.Background
        callback(0, "footer") if response.json.Footer
        callback(0, "logo") if response.json.Logo
        callback(0, "icon") if response.json.Icon
        callback(0, "strip") if response.json.Strip
        callback(0, "thumbnail") if response.json.Thumbnail
      else
        if response.statusCode is 404
          err.message = "Invalid image ID!"
        callback(err, null)
    , opt)  
  
  # ### uploadImage(role, path, callback) 
  # Uploads image located at `path` to the PassKit API for use as an image with
  # `role`, on success server returns `imageID` and `usage` string.
  # 
  # Allowed roles:
  #
  #     'background', 'footer', 'logo', 'icon', 'strip', 'thumbnail'
  #
  # Example return data:
  #
  #     {
  #       imageID: "sOmErAnDoMhEx",
  #       usage: "Background Image"
  #     }
  #
  uploadImage = (role, path, callback) ->
    # Make sure that image has valid role.
    if not (role in ["background", "footer", "icon", "logo", "strip", "thumbnail"])
      callback(new PassKitError("Role must be valid string!"), null)
      return

    # Check if file exists.
    # Node 0.6.x FIX
    exists = fs.exists || require('path').exists
    exists(path, (fileExists) ->
      if not fileExists
        callback(new PassKitError("Image does not exit: #{path}!"), null)
        return

      # Validate file type, only PNG, JPG and GIF images are valid.
      fileType = mime.lookup(path)
      # This won't be necessary exact extension but it's fine since we just need
      # it for creating typical file name for this image type because we need to
      # provide file name.
      uploadExtension = fileType.replace("image/", '')

      if not (fileType in ["image/png", "image/jpeg", "image/gif"])
        callback(new PassKitError("Invalid file type!"), null)
        return

      # Validate file size.
      fs.stat(path, (err, stats) ->
        if err
          callback(err, null)
          return

        if stats.size >= 1572864
          callback(new PassKitError("Image too large (larger than 1.5MB): #{stats.size}!"), null)
          return

        # If everything is fine proceed to reading contents and uploading image.
        fs.readFile(path, (err, data) ->
          # We are building request that should look something like this:
          #
          #     POST /v1/image/add/{role} HTTP/1.1
          #     Host: api.passkit.com
          #     Content-type: multipart/form-data, boundary={randomHex}
          #     Content-Length: {body.length}
          #
          #     --{randomHex}
          #     Content-Disposition: form-data; name="image"; filename="..."
          #     Content-Type: {fileType}
          #
          #     {data}
          #     --{randomHex}
          #     Content-Disposition: form-data; name="type"
          #
          #     {fileType}
          #     --{randomHex}--
          #
          # Credits: [http://chxo.com/be2/20050724_93bf.html](http://chxo.com/be2/20050724_93bf.html)
          #
          CRLF = "\r\n"
          boundary = "-----" + generateHex(12)
          separator = CRLF + "--" + boundary

          # Set headers for each data field.
          fileHeaders = [
            "Content-Disposition: form-data; name=\"image\"; filename=\"image.#{uploadExtension}\""
            "Content-Type: #{fileType}"
          ]
          inputHeaders = [
            "Content-Disposition: form-data; name=\"type\""
          ]

          buffers = [
              new Buffer(separator + CRLF + fileHeaders.join(CRLF) + CRLF + CRLF),
              data,
              new Buffer(separator + CRLF + inputHeaders.join(CRLF) + CRLF + CRLF),
              new Buffer(fileType),
              new Buffer(separator + "--")
            ]

          # Node 0.6.x FIX
          if process.version < 'v0.8'
            buffersLength = 0
            for b in buffers
              buffersLength += b.length

            body = new Buffer(buffersLength)
            targetStart = 0
            for b in buffers
              b.copy(body, targetStart)
              targetStart += b.length
          else
            # Join entire body.
            body = Buffer.concat(buffers)

          opt =
            headers: { "Content-Type": "multipart/form-data; boundary=#{boundary}" }
            method: "POST"
            path: "/image/add/#{role}/"

          request((err, response) ->
            if err
              callback(err, null)
            else
              callback(err, response.json)
          , opt, body)
        )
      )
    )






  # ## Pass functions

  # ### getPass(template, serial, callback)
  # Fetches pass with `serial` number from passes within same `template` name.
  #
  # Example response data:
  #
  #     { 
  #       serialNumber: '100000000001',
  #       templateName: 'test',
  #       uniqueID: 'uNiqUeIdEnT',
  #       templateLastUpdated: '2013-01-29T19:42:54+00:00',
  #       totalPasses: 1,
  #       passRecords: { 
  #         pass_1: { 
  #           passMeta: { 
  #             passStatus: 'Not Added',
  #             recoveryURL: 'https://r.pass.is/uNiqUeIdEnT',
  #             issueDate: '2013-01-29T23:22:26+00:00',
  #             lastDataChange: '2013-01-29T23:22:26+00:00',
  #             passbookSerial: 'pAsSbOoKSeRiAl' 
  #           }, 
  #           passData: { 
  #             owner: 'Name' 
  #           } 
  #         } 
  #       } 
  #     }
  #
  getPass = (template, serial, callback)  ->
    if not sanitize(template)
      callback(new PassKitError("Template name is required!"), null)
      return

    if not sanitize(serial)
      callback(new PassKitError("Pass serial number is required!"), null)
      return

    opt = 
      method: "GET"
      path: "/pass/get/template/#{encodeURIComponent(template)}/serial/#{encodeURIComponent(serial)}/"

    request((err, response) ->
      if err
        callback(err, null)
      else
        if response.json.totalPasses
          callback(err, response.json)
        else
          callback(new PassKitError("Template name or serial number is invalid!"), null)
    , opt)

  # ### getPassByID(passID, callback)
  # It does exactly the same as getPass but instead of `template` and `serial`
  # it uses `passID` that is unique pass identification number (the one used
  # in URL-s and called `uniqueID` in object data).
  getPassByID = (passID, callback)  ->
    if not sanitize(passID)
      callback(new PassKitError("Pass ID is required!"), null)
      return

    opt = 
      method: "GET"
      path: "/pass/get/passId/#{encodeURIComponent(passID)}/"

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid pass template name or serial number!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt)

  # ### invalidatePass(template, serial, fields, callback)
  # Irrecoverably invalidates pass with specified `serial`. After invalidation
  # it is no longer possible to update pass. If `fields` are provided it will 
  # update specified fields (this is useful for example updating data that is no
  # longer needed).
  #
  # Additionally fields support three specific keys (all by default `true`):  
  #
  #   - `removeBarcode` - barcode will be removed (not possible to scan it 
  # anymore)  
  #   - `removeLocations` - all locations will be removed (no more location 
  # based alerts)  
  #   - `removeRelevantDate` - relevant date will be removed (no more time based
  # alerts)
  #
  # Example return data:
  #
  #     {
  #         device_ids: "no registered devices",
  #         passes:1
  #     }
  #
  invalidatePass = (template, serial, fields, callback)  ->
    if not sanitize(template)
      callback(new PassKitError("Template name is required!"), null)
      return

    if not sanitize(serial)
      callback(new PassKitError("Pass serial number is required!"), null)
      return

    fields.removeBarcode = true if fields.removeBarcode is undefined
    fields.removeLocations = true if fields.removeLocations is undefined
    fields.removeRelevantDate = true if fields.removeRelevantDate is undefined

    opt =
      method: "POST"
      path: "/pass/invalidate/template/#{encodeURIComponent(template)}/serial/#{encodeURIComponent(serial)}/"

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid pass template name or serial number!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, fields, true)

  # ### issuePass(template, fields, callback) 
  # Issues new pass with given `template` design and populates its fields with
  # `fields` properties. On success returns pass `serial` (serial number in 
  # given template collection), `url` (unique shortened URL for sharing pass)
  # and `passbookSerial` that is for using with Apple's PKPassLibrary class.
  #
  # Optional field value is: `installIP` which will be used for statistics 
  # in your PassKit account.
  #
  # Example return data:
  #
  #     { 
  #       serial: '100000000001',
  #       url: 'https://r.pass.is/sOmErAnDoM',
  #       passbookSerial: 'SoMeRaNdOmLoNgHeX' 
  #     }
  #
  issuePass = (template, fields, callback)  ->
    if not sanitize(template)
      callback(new PassKitError("Template name is required!"), null)
      return

    data = JSON.stringify(fields)

    opt = 
      headers: { "Content-Type": "application/json" }
      method: "POST"
      path: "/pass/issue/template/#{encodeURIComponent(template)}/"

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Template name is invalid!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, data)

  # ### issueMultiplePasses(template, passes, callback)
  # It takes `template` name and object `passes` with list of passes as 
  # key-value pairs, each key will be used in response for returning result for 
  # that same object and value will be used as parameters for creating that 
  # specific pass.
  #
  # Example `passes` data:
  #
  #     {
  #       pass: {},
  #       pass2: { owner: 'Mickey' }
  #     }
  #
  # Example response data:
  #
  #     { 
  #       passes: { 
  #         pass: { 
  #           serial: '100000000001', 
  #           url: 'https://r.pass.is/rNdMhEx'
  #         },
  #         pass2: { 
  #           serial: '100000000002', 
  #           url: 'https://r.pass.is/rNdMhEx2' 
  #         } 
  #       },
  #       request_time: -0.203458 
  #     }
  #
  issueMultiplePasses = (template, passes, callback)  ->
    if not sanitize(template)
      callback(new PassKitError("Template name is required!"), null)
      return

    if not Object.keys(passes).length
      callback(new PassKitError("At least one pass must be provided!"), null)
      return

    if Object.keys(passes).length > 100
      callback(new PassKitError("Too many passes provided!"), null)
      return

    data = JSON.stringify(passes)

    opt =
      headers: { "Content-Type": "application/json" }
      method: "POST"
      path: "/pass/issue/batch/template/#{encodeURIComponent(template)}/"

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Template name is invalid!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, data)

  # ### updatePass(template, serial, fields, callback, \[push\])
  # It will update specified only `fields` singe pass with given `template` name
  # and `serial`. By default `push` is enabled and changes will be pushed to the
  # users device.
  #
  # Example response data:
  #
  #     {
  #       device_ids: "no registered devices",
  #       passes: 1
  #     }
  #
  updatePass = (template, serial, fields, callback, push=true)  ->
    if not sanitize(template)
      callback(new PassKitError("Template name is required!"), null)
      return

    if not sanitize(serial)
      callback(new PassKitError("Pass serial number is required!"), null)
      return

    if not Object.keys(fields).length
      callback(new PassKitError("Nothing to update!"), null)
      return

    opt =
      method: "POST"
      path: "/pass/update/template/#{encodeURIComponent(template)}/serial/#{encodeURIComponent(serial)}/"
    
    opt.path += "push" if push

    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid pass template name or serial number!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, fields, true)

  # ### updatePassByID(passID, fields, callback, \[push\])
  # It does exactly the same as updatePass but instead of `template` and 
  # `serial` it uses `passID`. By default `push` is enabled and changes will be 
  # pushed to the users device.
  updatePassByID = (passID, fields, callback, push=true)  ->
    if not sanitize(passID)
      callback(new PassKitError("Pass ID is required!"), null)
      return

    if not Object.keys(fields).length
      callback(new PassKitError("Nothing to update!"), null)
      return

    opt =
      method: "POST"
      path: "/pass/update/passid/#{encodeURIComponent(passID)}/"
    
    opt.path += "push" if push
    
    request((err, response) ->
      if err
        if response.statusCode is 404
          err.message = "Invalid pass template name or serial number!"
        callback(err, null)
      else
        callback(err, response.json)
    , opt, fields, true)





  # Map functions to the return object.
  return {
    request: request
    testConnection: testConnection
    # Template functions:
    getTemplates: getTemplates
    getTemplateFields: getTemplateFields
    resetTemplate: resetTemplate
    updateTemplate: updateTemplate
    # Image functions:
    getImageUsage: getImageUsage
    uploadImage: uploadImage
    # Pass functions:
    getPass: getPass
    getPassByID: getPassByID
    invalidatePass: invalidatePass
    issuePass: issuePass
    issueMultiplePasses: issueMultiplePasses
    updatePass: updatePass
    updatePassByID: updatePassByID
    # Helpers (public and private):
    helpers: 
      parsePassURL: parsePassURL
      supportsPassbook: supportsPassbook
    private:
      PassKitError: PassKitError
      generateHex: generateHex
      md5: md5
      parseDigest: parseDigest
      renderDigest: renderDigest
      sanitize: sanitize
  }

# Requiring this library should return Passkit class.
module.exports = PassKit