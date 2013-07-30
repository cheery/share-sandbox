express = require 'express'
sharejs = require 'share'
coffee = require 'coffee-script'

server = express()

server.use express.static('public')

cache = {}

compileLatest = (callback) ->
    server.model.getSnapshot 'main.coffee', (error, doc) ->
        if error
            callback error, null
        else if cache[doc.v]?
            callback null, cache[doc.v]
        else
            code = coffee.compile doc.snapshot, {
                filename: 'main.#{doc.v}.coffee'
                sourceMap: true
                generatedFile: "main.#{doc.v}.js"
                sourceFiles: ["main.#{doc.v}.coffee"]
            }
            postfix = "\n/*\n//@ sourceMappingURL=main.#{doc.v}.map\n*/"
            cache[doc.v] = code = {
                js: code.js + postfix
                v3SourceMap: code.v3SourceMap
                coffee: doc.snapshot
                v: doc.v
            }
            callback null, code

server.get '/main.*.map', (req, res, next) ->
    [version] = req.params
    code = cache[version]
    unless code?
        res.send("expired sourcemap", 404)
    else
        res.set('Content-Type', 'text/plain')
        res.send(code.v3SourceMap)

server.get '/main.*.coffee', (req, res, next) ->
    [version] = req.params
    code = cache[version]
    unless code?
        res.send("expired source file", 404)
    else
        res.set('Content-Type', 'text/coffeescript')
        res.send(code.coffee)

server.get '/main.*.js', (req, res, next) ->
    [version] = req.params
    code = cache[version]
    unless code?
        res.send("expired js file", 404)
    else
        res.set('Content-Type', 'text/javascript')
        res.send(code.js)

sandbox = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Run Sandbox</title>
    <script src="/lib/jquery.min.js"></script>
    <script src="/main.latest.js"></script>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <canvas id="canvas"></canvas>
</body>
</html>

"""
server.get '/run.html', (req, res, next) ->
    compileLatest (error, code) ->
        if error
            next(error)
        else
            res.set('Content-Type', 'text/html')
            res.send sandbox.replace('latest', "#{code.v}")

options = db: {type: 'none'}

sharejs.server.attach(server, options)

server.listen 8000, () ->
    console.log "server running at http://localhost:8000/"
    server.model.create('main.coffee', 'text')
