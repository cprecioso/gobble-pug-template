pug = require "pug"
sander = require "sander"
memoize = require "lodash.memoize"
{resolve} = require "path"

deleteReturn = (obj) -> (prop) ->
  ret = obj[prop]
  delete obj[prop]
  ret

readFile = (basedir) ->
  (path...) -> Promise.resolve sander.readFile basedir, path..., encoding: "utf8"

writeFile = (basedir) ->
  (path..., content) -> Promise.resolve sander.writeFile basedir, path..., content, encoding: "utf8"

compilePugFile = (basedir, options = {}) ->
  reader = readFile basedir
  memoize (path...) ->
    filename = resolve process.cwd(), basedir, path...
    reader path...
    .then (source) -> pug.compile source, Object.assign {}, options, {filename}

module.exports = class pugTemplate
  constructor: (inputdir, outputdir, options) ->
    fromOptions = deleteReturn options
    commonData = fromOptions("commonData") ? {}
    outputFn = fromOptions("outputFn")
    dataFilePath = fromOptions("dataFile")
    compiler = compilePugFile inputdir, options
    reader = readFile inputdir
    writer = writeFile outputdir
    
    return reader dataFilePath
    .then (str) -> JSON.parse str
    .then (dataFile) ->
      for {template, path, data} in Array.from outputFn dataFile
        throw new Error "You must yield the file.template" unless template?
        throw new Error "You must yield the file.path" unless path?
        data = Object.assign({}, dataFile, data ? {}, commonData)
        Promise.all([compiler(template), data, path])
        .then ([compile, data, path]) -> sander.writeFile outputdir, path, compile(data), encoding: "utf8"
    .then (arr) -> Promise.all arr
