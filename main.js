var _ = require('underscore'),
	jsonlint = require("jsonlint");

var jsontoolkit = module.exports = {
	parse: jsonlint.parse,
	stringify: JSON.stringify
}

// Require/parse utilities AFTER we declare exports
var utils = require('./lib/utilities');
_.each(utils, function(u, m) {
	jsontoolkit[m] = u;
});

jsontoolkit.Resource = require('./lib/resource');
jsontoolkit.Helper = jsontoolkit.Resource;