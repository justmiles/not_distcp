
require('coffeescript/register');

var mapper = require('./lib/mapper');

var reducer = require('./lib/reducer');

var processdiffs = require('./lib/processdiffs');

if (process.argv[2] === 'reduce') {
  reducer();
} else if (process.argv[2] === 'diff') {
  processdiffs();
} else {
  mapper();
}
