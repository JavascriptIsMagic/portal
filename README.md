# Portal 2.x Alpha
Portal: Portal = An opinionated Application Platform built on Amazon AWS + CoffeeScript + yield/generators and stream flow control.

This repository is incomplete and considered unstable, so it is not yet ready for production use.
====

Server Side Libraries Only:
`require 'portal/.coffee'`

Client Side Libraries Only:
`require 'portal/.cjsx'`

lib/async.coffee
------------
A simplified Async flow control similar to the `co` library but with native `Promise`s and without `thunk` support. (sort of like a `co`-lite)
`require 'portal/lib/async.coffee'`

lib/controller.coffee
---------------------
A simplified server-side controller library for doing `yield` and `next()` (sort of like a `koa`-lite)

TODO
====

Server
------
* [ ] Process Management
  * [x] PM2
  * [ ] Replace PM2
* [ ] Reverse HTTP Proxy
  * [x] Hipache (redis/elasticache)
  * [ ] Replace Hipache (redis/elasticache)
* [x] HTTP Server
  * [ ] Zones
  * [ ] HTTPS
  * [ ] Logging
    * [x] Logging to Console
      * [ ] Replace Chalk
    * [ ] Logging to Database (mongo/dynamo)
    * [ ] Error Logging (redis/elasticache)
  * [x] Options Requests
  * [ ] Templating Engine Support (ect)
    * [ ] Get Requests (html)
    * [ ] Emails
    * [ ] PDFs
    * [ ] Caching
      * [ ] Time to Live
        * [ ] Garbage collection
        * [ ] Memory Management
  * [x] Post Requests (json)
    * [x] Body Parse
    * [x] Controller Class
    * [ ] Authentication
      * [ ] Sessions (redis/elasticache)
      * [ ] Accounts
        * [ ] Login
          * [ ] Permissions
        * [ ] Profiles
        * [ ] Friends
      * [ ] Shared Document Management
        * [ ] Group Permissions
    * [ ] Search
    * [ ] Create
    * [ ] Remove
    * [ ] Update
* [ ] Testing
  * [ ] Process Management
  * [ ] Reverse HTTP Proxy
  * [ ] HTTP Server

Client
------
* [x] Build/Deploy Process
  * [x] Clean
  * [x] Copy Server Files
    * [x] Update NPM Dependencies
  * [x] Copy publicly served static files (images, pdfs, etc.)
  * [x] Browserify/Watchify
    * [x] .cjsx
  * [x] Debug/Watch Build Only
    * [x] Sourcemaps
  * [x] Production Build Only
    * [x] Minification
    * [x] Gzip
  * [x] Process Management
    * [x] PM2 (re)Launch Configuration
    * [x] PM2 Logs
  * [x] Automatic Version Incrementation
  * [x] Docs
  * [ ] Default Build Configuration and Stream Extensions
* [ ] Client Side Libraries
  * [ ] Ajax
    * [x] Request (api)
    * [ ] Upload
* [ ] Testing
  * [ ] React Testing
  * [ ] Bacon Testing
  * [ ] Async Testing
