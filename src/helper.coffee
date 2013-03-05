###
# This file provides a basic JSON object handling
###

json = require '../main'
_ = require 'underscore'
fs = require 'fs'
EventEmitter = require('events').EventEmitter

class JSONHelper extends EventEmitter
	constructor: (v, options) ->
		@options = _.defaults options,
			from_file: false,
			key_sep: ":",
			pretty_output: false,
			indent: "\t"

		# Default vars
		@data = null

		unless v
			@data = {}
			@emit "ready"
		else if _.isString(v)
			if @options.from_file
				@file = v
				json.parseFile v, (err, @data) =>
					if err then @emit "error", err
					else @emit "ready"
			else
				try
					@data = json.parse v
					@emit "ready"
				catch e then @emit "error", e	
		else
			@data = v
			@emit "ready"

	get: (key) ->
		unless key then return @data

		if _.isString(key) then keys = @_sepPath key
		else if _.isArray(key) and key.length then keys = key
		else return @emit "error", new Error "Expecting string or array."

		current = @data

		failed = _.find _.initial(keys), (item) ->
			if _.has(current, item) then return !(current = current[item])
			else return true
		
		if failed then return undefined
		else return current[_.last(keys)]

	set: (key, val) ->
		if _.isString(key) and key then keys = @_sepPath key
		else if _.isArray(key) and key.length then keys = key
		else return @emit "error", new Error "Expecting string or array for key."

		current = @data;

		# Traverse the tree. Stop right before the last key
		failed = _.some _.initial(keys), (item) =>
			# If it doesn't exist, make it an object
			unless _.has(current, item) then current[item] = {}
			
			# If it does exists, isn't the last key (can't be), and isn't an object, error up as a safety
			unless _.isObject(current[item])
				@emit "error", new Error("The key `#{item}` exists, but setting the value failed because it isn't a traversable object.")
				return true
			
			# Reset the current variable
			current = current[item]
			return false
		
		# Finally, set some bitches
		unless failed
			current[_.last(keys)] = val
			@emit "set", keys, val

	match: (key) ->
		stars = /([\\])?(\*\*?)/i
		one = "([^#{@options.key_sep}]*)"
		two = "(.*)"
		matches = []

		rmatch = (str) ->
			m = stars.exec(str)
			unless m then return str
			
			a = str.slice 0, m.index

			b = if m[1] then m[2]
			else if m[2] is "*" then one
			else if m[2] is "**" then two
			else m[0]

			c = rmatch str.slice m.index + m[0].length

			return a + b + c

		if _.isString(key) then key = new RegExp "^#{rmatch(key)}$"
		if !_.isRegExp(key)
			return @emit "error", new Error("Expecting string or regex.")

		@each (v, k) ->
			if key.test(k) then matches.push k

		return matches

	each: (start, cb) ->
		if _.isFunction(start) then [cb, start] = [start, null]
		
		r = (obj, base) =>
			base = if base then base + @options.key_sep else ""
			_.each obj, (v, k) ->
				k = base + k
				cb v, k
				if _.isObject(v) then r v, k

		r @get(start)

	test: (key, test) ->
		val = @get key

		if _.isString(test) then return typeof val is test
		else if _.isFunction(test) then return test.call null, val
		else if _.isRegExp(test) then return val.test(test)
		else return test is key

	# return first matched key
	find: (val) ->
		key = null

		_find = (obj, base) =>
			base = if base then base + @options.key_sep else ""
			_.some obj, (item, k) =>
				k = base + k
				if _.isEqual(val, item) then return key = k
				else if _.isObject(item) then _find item, k

		_find(@data)
		return key

	# returns all matched keys
	search: (val) ->
		keys = []

		_find = (obj, base) =>
			base = if base then base + @options.key_sep else ""
			_.each obj, (item, key) =>
				key = base + key
				if _.isEqual(val, item) then keys.push key
				if _.isObject(item) then _find item, key

		_find(@data)
		return keys

	save: (file, cb) ->
		if _.isFunction(file) then [cb, file] = [file, @file]
		unless file then file = @file or null
		indent = if @options.pretty_output then @options.indent else null

		json.saveJSON @data, file, indent, (err) =>
			if err
				if cb then cb err
				else @emit "error", err
			else
				@file = file
				if cb then cb()
				@emit "save", file

	toPrettyString: (indent) ->
		indent ?= @options.indent
		return json.prettify @data, indent

	toString: () ->
		return json.stringify @data

	toJSON: () ->
		return @data

	_sepPath: (p) ->
		return _.compact p.split @options.key_sep

module.exports = JSONHelper