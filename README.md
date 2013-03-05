# JSON Toolkit

This is a simple toolkit to make life with JSON easier in Node. On top of traditional `parse` and `stringify` methods, this toolkit helps retrieve JSON and traverse keys/values.

## Install

	npm install json-toolkit

## Usage

To use, simply require the package. JSON-Toolkit also has a `Helper` class (which is really the bulk of this thing) which is attached to the main object.

	var json = require("json-toolkit"),
		JSONHelper = json.Helper;

## API Documentation

### `json.parse( str )`

Parses `str` into Javascript. Internally uses `JSON.parse`.

### `json.stringify( obj [, replacer [, indent ] ] )`

Parses a `obj` into JSON. Internally uses `JSON.stringify`.

### `json.prettify( obj [, indent ] )`

Parses a `obj` into formatted JSON. `indent` is a string to use for indents or a number for the amount of spaces in an indent. Default for `indent` is `\t`.

### `json.parseFile( file, callback )`

Gets `file` contents and parses into Javascript. `callback` gives two arguments, `error` and `data`.

### `json.saveJSON( data, file [, indent ] [, callback ] )`

Parses `data` as JSON and saves to `file`. Using `indent` forces formatted printing (see above for usage). `callback` is called with one argument, `error`.

### `new (json.Helper)( file | JSON | data [, options ] )`

Creates a new `Helper` object. The constructor's first argument will take anything. If it's a string, it assumes that it is raw JSON or a filename (see `options`). If it's falsy, the internal data is set to `{}`. If it's anything else, it uses that.

`Helper` extends the Node class `EventEmitter` and has several events to capture. If using a filename in the constructor, you must capture the "ready" event before the object can be used.

One major thing to point out is that this uses path keys to traverse the data object. Anytime a method below has an argument named `key`, you can retrieve "deep" information by creating a "path" to it. This path is seperated by the option `key_sep`. Example: `get("dependencies:underscore") -> data["dependencies"]["underscore"]`

#### Options

* `from_file`, Default: `false`, Tells `Helper` that first argument into constructor is a filename and not raw JSON.
* `key_sep`, Default: `:`, The string seperator used to divide paths.
* `pretty_output`, Default: `false`, When saving, print formatted JSON.
* `indent`, Default: `\t`, When turning this object into formatted JSON, this string is used as the indent. (See above)

#### Properties

* `data` : Holds all of the parsed JSON data.
* `file` : Name of the file to save to. This is set on construction and each save.

#### Events

* `ready` : Emitted when the object is ready for use. Not necesary unless using a file for data instead of a string or object. Actually, any event capture with "ready" while using synchronous operations won't be fast enough and likely won't be ever called.
* `error` : Emitted when object encouters an error. They could also be thrown (not by hand!), so watch out.
* `set` : Emitted when a key is set. Gives to arguments, `keys` which is an array of keys representing the path and `value`.
* `save` : Emitted when a file is successfully saved.

#### Methods

##### `get( key )`

Retrieves the value at `key` in `data`. To transcend objects, seperate each key with `key_sep`.

##### `set( key, value )`

Sets `value` at `key` in `data`.

##### `match( key )`

Returns an array of all keys (deeply) that match `key`. On top of using the "path" for `key`, match introduces two special characters: `*` and `**`. A single `*` will match anything *up to the next `key_sep`*. A `**`, however, will match anything *including `key_sep`*.

For example, `deps:*` would match `deps:underscore` and `deps:foo`, but not `deps` or `deps:foo:bar`. `deps**` would match `deps` and `deps:foo` and `deps:foo:bar` but not `foo:deps`.

This method turns string `key` into a Regular Expression so any valid regex in `key` is compatible. This method will also accept a Regular Expression for `key` and will be significantly faster than using a string.

##### `each( [ start, ] iterative )`

Deeply loops through data at key `start` and calls `iterative` for each pair. `iterative` is a function with two arguments, `key` and `value`. If `value` is an object, `iterative` is called and then it will be called on all children values (hence the deep part).

##### `test( key, t )`

Test the value at `key` against `t`. If `t` is a string, then it is used in a `typeof` to test the value as a specifc type. If `t` is a function, then it is called with value as the only argument. If `t` is a regular expression, the value is tested against is. Anything else is matched for equality.

For example, `test("dependencies:underscore", "string")` would return true on this module's package.json.

##### `find( value )`

Deeply search data for `value` and return the *first* key that matches.

##### `search( value )`

Deeply search data for `value` and return *all* keys that match.

##### `save( [ file ] [, callback ] )`

Saves data as JSON to `file`. If `file` is not used, the internal file property is used instead. On completion, the internal file property is set to `file`. `callback` is called with one argument, `error`.

##### `toPrettyString( [ indent ] )`

Returns a formatted JSON string. `indent` is optional and by default will use `options.indent`.

##### `toString()`

Returns an unformatted JSON string.

##### `toJSON()`

Returns internal data object. This is useful for embedding into objects that will be converted into JSON.

## Example

	var job = new JSONHelper("package.json", {
		from_file: true,
		pretty_output: true
	});
	
	job.on("ready", function() {
		job.set("dependencies:underscore", "1.4.4");
		job.save();
	});
	
	job.on("save", function(file) {
		console.log("Saved JSON to "+file+".");
	});
	
	job.on("error", function(err) {
		console.error(err);
	});