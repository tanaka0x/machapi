const fetch = require('node-fetch')
const jsdom = require('jsdom')

function makeLogger(prefix) {
  return function(msg) {
    console.log(
      prefix + ':',
      Array.prototype.join.apply(arguments, [' '])
    )
  }
}

const OTAPA_ROOT = 'http://www.otapa.jp/'
const logger = makeLogger('OTAPA')

function request() {
  return fetch(OTAPA_ROOT)
    .then(res => res.text())
    .then(body => {
      const document = new jsdom.JSDOM(body).window.document
      const candidates = document.querySelectorAll('#daynavi > div > p > a')

      if (!candidates) {
	logger('failed to fetch candidates')
	return
      }

      let result = []
      for (let k in candidates) {
	const { href, innerHTML } = candidates[k]
	if (innerHTML) {
	  const minHref = parseHref(href)
	  const content = document.querySelector(minHref)
	  if (!content) {
	    logger('content was not found for', href)
	    return
	  }
	  
	  const title = content.querySelector('.event_title').innerHTML
	  const rows1 = content.querySelectorAll('.tbEvent01 > tbody > tr')
	  const rows2 = content.querySelectorAll('.tbEvent02 > tbody > tr')


	  let data = {
	    site: 'otapa',
	    title,
	    href: OTAPA_ROOT + minHref
	  }
	  
	  for (let rk in rows1) {
	    const el = rows1[rk]
	    if (!el.querySelector) {
	      continue
	    }
	    
	    const key = el.querySelector('th').innerHTML
	    const text = el.querySelector('td').innerHTML
	    if (!keyMap[key]) {
	      continue
	    }

	    data[keyMap[key]] = text
	  }

	  data.date = parseDate(data.date)
	  result.push(data)
	}
      }

      return result
    })
}

function parseHref(href) {
  return href.replace('about:blank', '')
}

function parseDate(org) {
  const parsed = org.match(/(\d+)年(\d+)月(\d+)日/)
  if (parsed) {
    return {
      y: parseInt(parsed[1]), m: parseInt(parsed[2]), d: parseInt(parsed[3]), original: org
    }
  }

  return { original: org }
}

const keyMap = {
  '開催日程': 'date',
  '開催場所': 'place'
}

module.exports = { request }
