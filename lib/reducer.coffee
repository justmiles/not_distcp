module.exports = ->
  process.stdin.on 'readable', ->
    chunk = process.stdin.read()
    
    return unless chunk
      
    lines = chunk.trim().split('\n')
    
    s3 = new AWS.S3()
    
    s3obj = new AWS.S3.ManagedUpload
      params:
        Bucket: process.env['S3_BUCKET']
        Key: (process.env['S3_PREFIX'] or '') + '/.sync/' + Math.floor(new Date() / 1000)
        Body: chunk
        
    s3obj.on 'httpUploadProgress', logProgress
    
    s3obj.send (err, res) ->
      if err?
        process.stderr.write "[ERROR] #{err}\n"
      else
        process.stdout.write "[UPLOADED] #{line}\n"
        process.stderr.write "[UPLOADED]\t#{line}\n"
      