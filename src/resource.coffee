###
# This file provides a basic JSON object handling
###

json = require '../main'
_ = require 'underscore'
fs = require 'fs'
SRPClass = require('./SRPClass')

class JSONResource extends SRPClass
	constructor: (v, options) ->
		@options = _.defaults options,
			from_file: false,
			key_sep: ":",
			pretty_output: false,
			indent: "\t"

		# Default vars
		@data = {}

		do_ready = _.once () =>
			@isReady = true
			@emit "ready"

		# Deal with "watching"
		@watching = {}
		@on "change", (key, val) =>
			if _.has(@watching, key) then @watching[key].call(null, key, val)

		# Handle input
		unless v then do_ready()

		# Is string and is filename
		if _.isString(v) and @options.from_file
			@file = v

			# Check if it exists because we don't care if it doesn't
			fs.exists v, (exists) =>
				if exists
					@load v, (err) =>
						if err then @emit "error", err
						else do_ready()
				else do_ready()
		
		# Otherwise have load handle it
		else
			@load v
			do_ready()

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
			@emit "change", keys.join(@options.key_sep), val

	test: (key, value) ->
		val = @get key

		if _.isString(value) then return typeof val is value
		else if _.isFunction(value) then return value.call null, val
		else if _.isRegExp(value) then return val.test(value)
		else return value is val

	match: (key) ->
		stars = /([\\])?(\*\*?)/i
		one = "([^#{@options.key_sep}]*)"
		two = "(.*)"
		matches = []
		start = null

		rmatch = (str) ->
			m = stars.exec(str)
			unless m then return [ str, "", "" ]
			
			a = str.slice 0, m.index

			b = if m[1] then m[2]
			else if m[2] is "*" then one
			else if m[2] is "**" then two
			else m[0]

			c = rmatch(str.slice(m.index + m[0].length)).join("")

			return [ a, b, c ]

		if _.isString(key)
			[ a, b, c ] = rmatch(key)
			s = a.split(@options.key_sep)
			
			start = _.initial(s).join(@options.key_sep)
			key = new RegExp "^#{_.last(s)+b+c}$"
		
		if !_.isRegExp(key)
			@emit "error", new Error("Expecting string or regex.")
			return []

		reach = (obj, base) =>
			base = if base then base + @options.key_sep else ""
			_.each obj, (v, k) ->
				k = base + k
				if key.test(k) then matches.push k
				if _.isObject(v) then reach v, k

		value = @get(start)
		if _.isObject(value) then reach(value)
		else matches = [ "" ]

		matches = _.map matches, (m) =>
			return start + @options.key_sep + m

		return matches

	replace: (key, val) ->
		@each key, (x, k) =>
			if _.isFunction(val) then v = val @get(k), k
			else v = val

			@set k, v

	each: (key, cb) ->
		if _.isFunction(key) then [cb, key] = [key, null]
		ms = @match key or "**"
		_.each ms, (k) =>
			cb(@get(k), k, ms)

	watch: (key, cb) ->
		if _.isFunction(key) and !cb then [cb, key] = [key, "**"]
		unless _.isFunction(cb) and _.isString(key) then return

		keep = _.chain(@match(key)).map((k) -> return [ k, cb ]).object().value()
		_.extend @watching, keep

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

	load: (data, cb) ->
		old = @toObject()

		if _.isFunction cb
			return json.parseFile data, (err, obj) =>
				if err then cb err
				else
					_.extend @data, obj
					cb null, old
					@emit "load", old

		try 
			if _.isString data then data = json.parse data
			_.extend @data, data
		catch e then return @emit "error", e

		@emit "load", old
		return old

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
		return @toObject()

	toObject: () ->
		return _.clone(@data)

	_sepPath: (p) ->
		return _.compact p.split @options.key_sep

module.exports = JSONResource