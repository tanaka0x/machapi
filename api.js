const fs = require('fs')
const express = require('express')
const { promisify } = require('util')
const compression = require('compression')

const port = process.env.API_PORT ? parseInt(process.env.API_PORT) : 8080

const app = express()
app.use(compression())

app.listen(port)

const readFile = promisify(fs.readFile)
app.get('/events', (req, res) => {
  
  const promisses = ['otapa.json', 'koikoi.json'].map(s => {
    return readFile(s, 'utf-8').then(data => JSON.parse(data))
  })

  Promise.all(promisses).then(values => {
    return values.reduce((l, r) => l.concat(r))
  }).then(result => {
    res.json(result)
  }).catch(e => {
    console.log('Error: ', e.toString())
    res.status(500).send('')
  })
  
})
