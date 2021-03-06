WebHDFS     = require 'webhdfs'
fs          = require 'fs'
AWS         = require 'aws-sdk'
shortid     = require 'shortid'
async       = require 'async'
readline    = require 'readline'
logProgress = require './s3_progress_logger'
zlib        = require 'zlib'

s3   = new AWS.S3()
gzip = zlib.createGzip()
hdfs = WebHDFS.createClient
  user: process.env['HDFS_USER'] or 'hdfs'
  host: process.env['NAMENODE']
  port: process.env['WEB_HDFS_PORT'] or 50070 

counter = (subject)->
  process.stderr.write "reporter:counter:HDFS Files Processed,#{subject},1\n"

status = (message)->
  process.stderr.write "reporter:status:#{message}\n"

uploader = (s3obj, line, tmpfile, retries= 3, callback) ->
  status "[UPLOADING] #{line}"
  retries -= 1
  s3obj.send (err, res) ->
    if err?
      counter 'S3_UPLOAD_ERRORS'
      if retries > 0
        status "[S3_UPLOAD_ERROR] #{line} #{err}\n [S3_UPLOAD_ERROR] Retrying #{retries} more times"
        uploader s3obj, line, tmpfile, retries, callback
      else
        status "[S3_UPLOAD_FAIL] #{line} #{err}\n no more retries. cancelling"
        counter 'S3_UPLOAD_FAIL'
        s3obj.abort()
        fs.unlink tmpfile
        callback '#{line} no more retries. cancelling'
    else
      status "[UPLOADED]\t#{line})"
      counter 'UPLOADED'
      fs.unlink tmpfile
      do callback

processLine = (line, callback) ->
  s3params = 
    Bucket: process.env['S3_BUCKET']
    Key: (process.env['S3_PREFIX'] or '')+line+'.gz'
    
  async.waterfall [
    
    # Gzip HDFS file to local cache
    (cb) ->
      remoteFileStream = hdfs.createReadStream(line)
      tmpfile = 's3_cache_' + shortid.generate()
      wstream = fs.createWriteStream(tmpfile)
      status "[CACHING] #{line}"
      counter 'CACHING'
      remoteFileStream.pipe(zlib.createGzip()).pipe(wstream)

      remoteFileStream.on 'error', (error) ->
        status "[WEBHDFS_ERROR] #{line} #{error}"

      remoteFileStream.on 'finish', ->
        hdfs.stat line, (err, res) ->
          cb err, tmpfile
          if err
            counter 'HDFS_ERROR'
            status "[WEBHDFS_ERROR] #{line} #{err}"
          else
            status "[CACHED] #{line}"
            counter 'CACHED'

    # Compare Gzipped HDFS file against the desired S3 key
    (tmpfile, cb) ->
      stats = fs.statSync tmpfile
      s3.headObject s3params, (err, data) ->
          if err
            return cb null, tmpfile
          else if stats?.size == data?.ContentLength
            status "[SKIPPING] #{line}"
            counter 'SKIPPED'
            return cb 'skipping'
          else
            status "[OUTOFSYNC] #{line}"
            return cb null, tmpfile

    (tmpfile, cb) ->
      stats = fs.statSync tmpfile
      s3params['Body'] = fs.createReadStream(tmpfile)
      s3obj = new AWS.S3.ManagedUpload
        params: s3params

      s3obj.on 'httpUploadProgress', logProgress
      uploader s3obj, line, tmpfile, retries=3, cb

  ], callback


module.exports = ->

  rl = readline.createInterface
    input: process.stdin
  
  q = async.queue processLine, (process.env['PARALLELISM'] or 1)
  
  rl.on 'line', (line) ->
    counter 'QUEUED'
    q.push line, ->
      console.log "Finished processing #{line}" if process.env['DEBUG']
      counter 'PROCESSED'
      process.stdout.write "[PROCESSED] #{line}\n"
