var EventEmitter = require('events').EventEmitter,
	__hasProp = {}.hasOwnProperty,
	__extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child._super = parent.prototype; return child; };

/**
Simple Resource Protocol is designed to create a standard model for accessing many different types of resources. This works best in an event driven environment (hence why it's set up for Node.js/JavaScript) but is loose enough in implementation to be easily translated.

You can extend this Class directly or write your own. Either way, the resulting Object should contain these methods.

@module SRPClass
**/
var SRPClass = (function() {
	
	__extends(SRPClass, EventEmitter);

	/**
	* Simple Resource Protocol Class base. The contructor will usually take two arguments, an identifier (`id`) and and object of `options`. While the constructor is ultimately up to interpretation, including the `options` is a good idea. 
	*
	* @class SRPClass
	* @constructor
	* @extends EventEmitter
	* @param {Mixed} [id] An identifier to help you deal with multiple sets. Example: Base folder for file system resource.
	* @param {Object} options An object of additional options
	*   @param {String} options.key_sep If the class supports dynamic keys, this is how they are seperated.
	*/
	function SRPClass(id, options) {
		options = typeof options === "object" ? options : {};
		this.options = {};

		this.options.key_sep = options.key_sep || ":";
	}

	SRPClass.prototype.get = function(key) { };
	SRPClass.prototype.set = function(key, value) { };
	SRPClass.prototype.test = function(key, value) { };

	SRPClass.prototype.match = function(key) { };
	SRPClass.prototype.each = function(key, iterative) { };
	SRPClass.prototype.replace = function(key, iterative) { };
	SRPClass.prototype.watch = function(key, callback) { };

	SRPClass.prototype.find = function(value) { };
	SRPClass.prototype.search = function(value) { };

	SRPClass.prototype.save = function(id, callback) { };
	SRPClass.prototype.load = function(data, callback) { };

	SRPClass.prototype._sepPath = function(p) {
		return p.split(this.options.key_sep).filter(function(part) {
			return part ? true : false;
		});
    };

	return SRPClass;
	
})();

module.exports = SRPClass;