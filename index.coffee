require 'coffeescript/register'
mapper = require('./lib/mapper')
reducer = require('./lib/reducer')
processdiffs = require('./lib/processdiffs')
if process.argv[2] == 'reduce'
  reducer()
else if process.argv[2] == 'diff'
  processdiffs()
else
  mapper()
