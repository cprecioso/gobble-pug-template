const pug = require("pug")
const sander = require("sander")
const path = require("path")

function pugTemplate(inputdir, outdir, options, callback) {
  const template = path.resolve(inputdir, options.template)
  delete options.template

  const data = options.data || {}
  delete options.data
  
  return Promise.resolve().then(() => {
    return sander.readdir(inputdir)
  }).then(list => {
    return Promise.all(
      list
        .filter(file => path.extname(file) === ".json")
        .map(file =>
          sander.readFile(path.resolve(inputdir, file))
          .then(JSON.parse)
          .then(json => ({[path.basename(file, ".json")]: json}))
        )
    ).then(objs => objs.reduce((acc, cur) => Object.assign(acc, cur), {}))
  }).then(obj => {
    const fn = pug.compileFile(template, options)
    const promArr = []
    for (const key in obj) {
      promArr.push(sander.writeFile(path.resolve(outdir, key + ".html"), fn(Object.assign({}, obj[key], data)), {encoding: "utf8"}))
    }
    return Promise.all(promArr)
  })
}

module.exports = pugTemplate
