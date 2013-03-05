var _ = require('underscore');

var jsontoolkit = module.exports = {
	parse: JSON.parse,
	stringify: JSON.stringify
}

// Require/parse utilities AFTER we declare exports
var utils = require('./lib/utilities');
_.each(utils, function(u, m) {
	jsontoolkit[m] = u;
});

jsontoolkit.Helper = require('./lib/helper');