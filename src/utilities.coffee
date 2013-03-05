###
# This file provides simple JSON extensions
###

path = require 'path'
fs = require 'fs'
_ = require 'underscore'
json = require '../main'

parseFile = module.exports.parseFile = (file, cb) ->
	fs.readFile file, 'utf-8', (err, data) ->
		if err then cb(err)
		else cb null, json.parse data

prettify = module.exports.prettify = (v, indent) ->
	indent ?= "\t"
	return json.stringify v, null, indent

saveJSON = module.exports.saveJSON = (data, file, indent, cb) ->
	if _.isFunction(indent) then [cb, indent] = [indent, null]
	cb = if _.isFunction(cb) then _.once cb else () ->
	fstream = fs.createWriteStream(file, { flags: "w" })

	fstream.on "error", (err) =>
		cb err

	fstream.on "close", () =>
		cb()

	fstream.end json.stringify data, null, indent