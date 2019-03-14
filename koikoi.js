const fetch = require('node-fetch')
const jsdom = require('jsdom')

const KOIKOI_ROOT = 'https://koikoi.co.jp/ikoiko/'
const LIST_PAGE = KOIKOI_ROOT + 'list_1/'

function request() {
  return fetch(LIST_PAGE)
    .then(res => res.text())
    .then(body => {
      const document = new jsdom.JSDOM(body).window.document
      const candidates = document.querySelectorAll('#resultList > div.event')
      
      if (!candidates) {
	throw 'failed to fetch candidates'
      }

      const today = new Date()
      let result = []
      for (let k in candidates) {
	const ev = candidates[k]
	if (!ev || !ev.querySelector) {
	  continue
	}
	
	const href = ev.querySelector('a').href
	const info = ev.querySelector('.eventInfo')
	const title = info.querySelector('.eventName > a').innerHTML
	const date = info.querySelector('.dateTime').innerHTML

	result.push({
	  site: 'koikoi',
	  title,
	  href: KOIKOI_ROOT + href.replace('//koikoi.co.jp/ikoiko/', ''),
	  date: date ? parseDate(date, today) : date,
	  place: parsePlace(title)
	})
      }
      return result
    })
}

function parsePlace(org) {
  const tokens = org.split('in ')
  if (!tokens || tokens.length < 2) {
    return null
  }

  return tokens[1]
}

function parseDate(org, today) {
  const parsed = org.match(/(\d+)月(\d+)日/)

  if (parsed) {
    const todayYear = today.getFullYear()
    const todayMonth = today.getMonth() + 1
    const todayDay = today.getDate()
    
    const m = parseInt(parsed[1])
    const d = parseInt(parsed[2])

    let y = todayYear
    if (m < todayMonth || (m === todayMonth && d < todayDay)) {
      y += 1
    }
    
    return {
      y, m, d, original: org
    }
  }

  return { original: org }
}

module.exports = { request }
