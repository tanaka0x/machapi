const fs = require('fs')
const otapa = require('./otapa')
const koikoi = require('./koikoi')

const errorFile = 'error.log'

otapa.request().then(result => {
  // result.forEach(i => console.log(JSON.stringify(i)))
  fs.writeFileSync('otapa.json', JSON.stringify(result))
}).catch(e => {
  const msg = e ? e.toString() : "unknown error"
  fs.appendFileSync(errorFile, 'OTAPA: ' + msg + '\n')
})

koikoi.request().then(result => {
  // result.forEach(i => console.log(JSON.stringify(i)))
  fs.writeFileSync('koikoi.json', JSON.stringify(result))
}).catch(e => {
  const msg = e ? e.toString() : "unknown error"
  fs.appendFileSync(errorFile, 'KOIKOI: ' + msg + '\n')
})
