// Importy Sinon mocking framework and Chai assertion library
global.sinon = require("sinon");
global.chai = require("chai");
global.expect = require('chai').expect
global.should = require("chai").should();

global.USER = "[API_USER]"
global.PASS = "[API_SECRET]"

global.SERVER = false
global.TOTAL = false

// Nock for URL mocking
global.nock = require("nock")
global.https = require("https")

global.passkit_src = require("./lib/passkit")
global.passkit = require("./lib/passkit")(USER, PASS)