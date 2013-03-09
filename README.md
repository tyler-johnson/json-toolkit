# JSON Toolkit

This is a simple toolkit to make life with JSON easier in Node. On top of traditional `parse` and `stringify` methods, this toolkit helps retrieve JSON and traverse keys/values.

## Install

	npm install json-toolkit --save

The `--save` will tell npm is add it to your `package.json`.

## Usage

To use, simply require the package. JSON-Toolkit also has a `Resource` class (which is really the bulk of this thing) which is attached to the main object.

	var json = require("json-toolkit"),
		JSONR = json.Resource;

## API Documentation

### `json.parse( str )`

Parses `str` into Javascript. Internally uses `jsonlint.parse`. Throws any validation errors.

### `json.validate( str )`

Attempts to parses `str` into Javascript and uses jsonlint to validate. If a validation error is found, it is returned. Otherwise, `null` is returned on valid JSON.

### `json.stringify( obj [, replacer [, indent ] ] )`

Parses a `obj` into JSON. Internally uses `JSON.stringify`.

### `json.prettify( obj [, indent ] )`

Parses a `obj` into formatted JSON. `indent` is a string to use for indents or a number for the amount of spaces in an indent. Default for `indent` is `\t`.

### `json.parseFile( file, callback )`

Gets `file` contents and parses into Javascript. `callback` gives two arguments, `error` and `data`.

### `json.saveToFile( data, file [, indent ] [, callback ] )`

Parses `data` as JSON and saves to `file`. Using `indent` forces formatted printing (see above for usage). `callback` is called with one argument, `error`.

This method used to be `saveJSON()`. The name was changed to better represent what it does. Both functions will do the same thing.

### `new (json.Resource)( file | JSON | data [, options ] )`

Creates a new `Resource` object. The constructor's first argument will take anything. If it's a string, it assumes that it is raw JSON or a filename (see `options`). If it's falsy, the internal data is set to `{}`. If it's anything else, it uses that.

`Resource` extends the Node class `EventEmitter` and has several events to capture. If using a filename in the constructor, you must capture the "ready" event before the object can be used. This class used to be named `Helper` and is still accessible by that handle.

One major thing to point out is that this uses path keys to traverse the data object. Anytime a method below has an argument named `key`, you can retrieve "deep" information by creating a "path" to it. This path is seperated by the option `key_sep`. Example: `get("dependencies:underscore") -> data["dependencies"]["underscore"]`

#### Options

* `from_file`, Default: `false`, Tells `Resource` that first argument into constructor is a filename and not raw JSON. Must wait for "ready" event before the object is usable. If the file doesn't exist, the object ignores that, assuming you are creating a new JSON document.
* `key_sep`, Default: `:`, The string seperator used to divide paths.
* `pretty_output`, Default: `false`, When saving, print formatted JSON.
* `indent`, Default: `\t`, When turning this object into formatted JSON, this string is used as the indent. (See above)

#### Properties

* `data` : Holds all of the parsed JSON data.
* `file` : Name of the file to save to. This is set on construction and each save.

#### Events

* `ready` : Emitted when the object is ready for use. Not necesary unless using a file for data instead of a string or an object. Actually, any "ready" event you declare while using synchronous operations (ie, no FS calls) won't be fast enough and likely won't ever be called.
* `error` : Emitted when object encouters an error. It should be noted that errors have the possibility of being thrown and not captured by this event. If you come across one, please let me know.
* `change` : Emitted when a key is set. Gives two arguments, `keys`, which is an string path and `value`.
* `load` : Emitted when object completes a load. Gives a single argument, `old_data` which is an object representing the previous state of data.
* `save` : Emitted when a file is successfully saved. Gives a single argument, `file`.

#### Methods

##### `get( key )`

Retrieves the value at `key` in data. To transcend objects, seperate each key with `key_sep`.

##### `set( key, value )`

Sets `value` at `key` in data.

##### `test( key, t )`

Test the value at `key` against `t`. If `t` is a string, then it is used in a `typeof` to test the value as a specifc type. If `t` is a function, then it is called with value as the only argument. If `t` is a regular expression, the value is tested for matches. Anything else is matched for equality.

For example, `test("dependencies:underscore", "string")` would return true on this module's package.json.

##### `match( key )`

Returns an array of all keys (deeply) that match `key`. On top of using the "path" for `key`, match introduces two special characters: `*` and `**`. A single `*` will match anything *up to the next `key_sep`*. A `**`, however, will match anything *including `key_sep`*.

For example, `deps:*` would match `deps:underscore` and `deps:foo`, but not `deps` or `deps:foo:bar`. `deps**` would match `deps` and `deps:foo` and `deps:foo:bar` but not `foo:deps`.

This method turns string `key` into a Regular Expression so any valid regex in `key` is compatible. This method will also accept a Regular Expression for `key` and will be significantly faster than using a string.

##### `each( [ match, ] iterative )`

Loops through all keys returned from `match` (see above) and calls `iterative` for each key. `iterative` is a function with three arguments, `value`, `key`, and `list`. This is useful when trying to dynamically process keys/values, however it is very inefficient and should not be your "go-to" loop.

##### `replace( [ match, ] value )`

Loops through all keys returned from `match` (see above) and sets them to `value`. `value` can also an iterative function that should return a new value for the key. It is called with three arguments, `value`, `key`, and `list`.

##### `watch( [ match, ] callback )`

Waits for changes on keys that `match` and calls `callback` with two arguments: `key` and `value`.

##### `find( value )`

Deeply search data for `value` and return the *first* key that matches.

##### `search( value )`

Deeply search data for `value` and return *all* keys that match.

##### `load( data [, callback ] )`

Extends the internal data with `data` (*not* deep). If `callback` is passed, data is assumed to be a filename and this will instead retrieve and parse JSON. The constructor uses this to handle the first argument.

##### `save( [ file ] [, callback ] )`

Saves data as JSON to `file`. If `file` is not provided, the internal file property is used instead. On completion, the internal file property is set to `file`. `callback` is called with one argument, `error`.

##### `toPrettyString( [ indent ] )`

Returns a formatted JSON string. `indent` is optional and by default will use `options.indent`.

##### `toString()`

Returns an unformatted JSON string.

##### `toJSON()`

Returns internal data object. This is useful for embedding into objects that will be converted into JSON.

## Example

Basic usage with the JSON `Resource`.

```js
var job = new JSONR("package.json", {
	from_file: true,
	pretty_output: true
});
	
job.on("ready", function() { // Wait for file to import
	job.set("dependencies:underscore", "1.4.4"); // Set a single key
	job.replace("dependencies:*", function(v, k) { // Set a key by match
		console.log(k, "=>", v);
		return '9.9.9';
	});
	job.save(); // Save the file
});
	
job.on("save", function(file) { // When save is successfuly
	console.log("Saved JSON to "+file+".");
});
	
job.on("error", function(err) { // When an error is thrown
	console.error(err);
});
```

Loading and watching.

```js
// New Resource, file doesn't exist so ignore that for saving later
var h = new JSONR('asdf.json', { from_file: true, pretty_output: true });

h.on("ready", function() {
	h.load("package.json", function(err) { // Load the current package.json
		if (err) return console.log(err.stack);
		h.watch("dependencies:*", function(key, value) { // Watch for any changes on dependencies
			console.log("Changed " + key + " to " + value);
		});

		// Some time later...
		setTimeout(function() {
			h.set("dependencies:underscore", "9.9.9");
			h.set("dependencies:jsonlint", "9.9.9");
		}, 3000);
	});
});
```

## Feedback/Suggestions

I really want to extend this library to include many different JSON tools. These are only the ones that I have personally needed in the past. If you have a suggested addition to this library, I'd love to hear it (and probably add it). Of course, I (Tyler Johnson) am always reachable at <tyler@vintyge.com>.