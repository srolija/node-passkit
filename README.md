# Node-PassKit

This package makes using PassKit API simple by removing overhead of authenticating using Digest authentication and by implementing all of the available API endpoints as simple functions.

## Installation

Compatible with Node >= 0.6.x, tested on Node 0.6.10 and 0.8.7.
To install simply run following command:

```
$ npm install passkit
```

## Example

Lets start with requiring PassKit package, we need to provide `API_USER` and `API_SECRET` that were mailed to us after registration.

```javascript
var passkit = require('passkit')("[API_USER]", "[API_SECRET]")
```

Then given we have created template named `test` in PassKit pass Designer and it has field `owner` we can issue new pass with custom owner name like this:


```javascript
passkit.issuePass('test', {owner: 'Me'}, function(err, data){
  console.log('issuePass:');
  if (err) {
    console.error(err);
  } else {
    console.log(data);
  }
});
```

After about second we should see something like this:

```
{ 
  serial: '100000000001',
  url: 'https://r.pass.is/sOmErAnDoM',
  passbookSerial: 'SoMeRaNdOmLoNgHeX' 
}
```

For more information, tips and API reference please look at [annotated source code](http://srolija.github.com/node-passkit).


## Tests

If you plan on using this package on newer or older version of Node it is highly recommended that you run tests to verify that everything is working as expected.

You can run tests simply by going to package directory installing dependencies and running:

```
npm test
```

If you want to run tests as integration tests (to verify if some of API endpoints maybe changed and would cause different response) enter your API info in `test_helper.js`, then create new template in your account on PassKit called `test` and create single dynamic field named `owner`. 

Then in `test_helper.js` set following:

```
global.SERVER = true
global.TOTAL = true
```

And run tests normally. Keep in mind that API changes and possible errors on connection or internal Server Errors could fail those tests! Also each time before you run integration tests go to `test` template in PassKit Pass Deisgner and save template, doing this prevents error when trying to reset template.

Keep in mind that integration tests **do not cover entire API** just most important parts of it, other tests do cover entire API that is implemented!


## Versions

### 0.8.1
Date 3/29/2013

Fixed Content-Length problem. 
Recompiled with latest coffee-script.

### 0.8.0
Date: 1/31/2013

Initial public release.
