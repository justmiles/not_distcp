# not_distcp
Reads a list of file names on HDFS from stdin and uploads each file to S3

There's probably a better way to ship files from HDFS to S3. Hadoop supports this via `distcp`, but `distcp` doesn't let you specify a list of files to upload. This fills that gap. 

## Environment Variables

   | Variable       | Description                                         | Status         |
   | :------------- | :-------------                                      | :------------- |
   | NAMENODE       | namenode for web hdfs                               | 127.0.0.1      |
   | WEB_HDFS_PORT  | namenode port for web hdfs                          | 50070          |
   | HDFS_USER      | namenode user                                       | hdfs           |
   | S3_BUCKET      | S3 bucket to upload to                              | -              |
   | S3_PREFIX      | Prefix for your files (before their original path)  | ''             |
   | PARALLELISM    | How many files to upload at a time                  | 1              |

## Usage
Pipe a list of file names (full path) into not_distcp

    echo "/user/hdfs/file_to_upload" | ./bin/not_distcp-0.0.2-linux
    
or a from a list of files

    ./bin/not_distcp-0.0.2-linux < mylist.txt
