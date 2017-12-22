prettyBytes = require 'pretty-bytes'

module.exports = (progress) ->
  process.stderr.write "[INFO] #{(progress.loaded/progress.total * 100).toFixed(2)}% Uploaded #{prettyBytes(progress.loaded)} of #{prettyBytes(progress.total)} - s3://#{process.env['S3_BUCKET']}/#{progress.key}\n" if progress.total
  