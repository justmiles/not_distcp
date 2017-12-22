WebHDFS     = require 'webhdfs'
AWS         = require 'aws-sdk'
async       = require 'async'

hdfs = WebHDFS.createClient
  user: process.env['HDFS_USER'] or 'hdfs'
  host: process.env['NAMENODE']
  port: process.env['WEB_HDFS_PORT'] or 50070 

module.exports = ->
  readline = require('readline')
  s3 = new AWS.S3()

  rl = readline.createInterface
    input: process.stdin
  
  rl.on 'line', (line) ->
    rl.pause()
    hdfs.stat line, (err, hdfsFile) ->
      if err
         process.stdout.write "[HDFS] #{line} #{err}\n"
         return
      else
        s3.headObject {
          Bucket: process.env['S3_BUCKET']
          Key: (process.env['S3_PREFIX'] or '')+line
        }, (err, data) ->
          if err
            process.stdout.write "[S3STAT] #{line} #{err}\n"
          else if hdfsFile?.length == data?.ContentLength
            process.stdout.write "[INSYNC] #{line}\n"
          else
            process.stdout.write "[OUTOFSYNC] #{line}\n"
          rl.resume()
      

