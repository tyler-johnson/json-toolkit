###
# This file provides simple JSON extensions
###

path = require 'path'
fs = require 'fs'
_ = require 'underscore'
jsonlint = require 'jsonlint'
json = require '../main'

parseFile = module.exports.parseFile = (file, cb) ->
	fs.readFile file, 'utf-8', (err, data) ->
		if err then cb(err)
		else
			try cb null, json.parse data
			catch e then cb(e)

prettify = module.exports.prettify = (v, indent) ->
	indent ?= "\t"
	return json.stringify v, null, indent

saveToFile = module.exports.saveToFile = (data, file, indent, cb) ->
	if _.isFunction(indent) then [cb, indent] = [indent, null]
	cb = if _.isFunction(cb) then _.once cb else () ->
	fstream = fs.createWriteStream(file, { flags: "w" })

	fstream.on "error", (err) =>
		cb err

	fstream.on "close", () =>
		cb()

	fstream.end json.stringify data, null, indent

saveJSON = module.exports.saveJSON = saveToFile # Keep old API

validate = module.exports.validate = (rawjson) ->
	try
		json.parse rawjson
		return null
	catch e then return e