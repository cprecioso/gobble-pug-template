pug = require "pug"
sander = require "sander"
memoize = require "lodash.memoize"
{wrap: async} = require "co"
{resolve} = require("path")

deleteReturn = (obj) -> (prop) ->
  ret = obj[prop]
  delete obj[prop]
  ret

compilePugFile = (basedir, options = {}) ->
  memoize async (filename) ->
    source = yield sander.readFile basedir, filename, encoding: "utf8"
    pug.compile source, Object.assign {}, options, {filename: resolve basedir, filename}

pugTemplate = async (inputdir, outputdir, options) ->
  fromOptions = deleteReturn options

  dataFile = JSON.parse yield sander.readFile inputdir, fromOptions("dataFile"), encoding: "utf8"
  commonData = (fromOptions "commonData") ? {}
  outputFn = fromOptions "outputFn"

  compiler = compilePugFile inputdir, options

  iterator = outputFn dataFile
  until (iteration = iterator.next()).done
    {template, path, data} = iteration.value

    throw new Error "You must yield the file.template" unless template?
    throw new Error "You must yield the file.path" unless path?
    
    data = Object.assign({}, data ? {}, commonData)

    yield sander.writeFile outputdir, path, (yield compiler template)(data), encoding: "utf8"

module.exports = pugTemplate
