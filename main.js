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

var Helper = require('./lib/helper');
jsontoolkit.Helper = Helper;

var job = new Helper("package.json", { from_file: true });

job.on("ready", function() {
	job.set("dependencies:nconf", "0.4.7");
	job.replace("dependencies:*", function(v, k) {
		console.log(k, "=>", v);
		return true;
	});
	console.log(job.get());
});