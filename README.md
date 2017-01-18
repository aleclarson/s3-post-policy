
# s3-post-policy v1.1.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

```coffee
PostPolicy = require "s3-post-policy"

policy = PostPolicy
  region: "us-east-1"                  # the required region
  bucket: "example-bucket"             # the required bucket
  acl: "public-read"                   # the required access control
  key: "users/bobby"                   # (optional) can be exact file, or the required directory
  metadata: {uuid: "14365123651274"}   # (optional) any name/value pair works
  contentType: "image/png"             # (optional) the required content-type. Defaults to none
  contentLength: [1, 1e6]              # (optional) the content-length range or max value. Defaults to no limit

data = policy.sign
  date: new Date                       # (optional) the date used to sign the policy
  expires: 5                           # (optional) the minutes until the signature expires. Defaults to 30 minutes
  accessKeyId: "AKIAIOSFODNN7EXAMPLE"                         # the S3 access key ID
  secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" # the S3 secret access key

data.policy     # The policy base64-encoded
data.signature  # The policy signature
data.expiration # The policy expiration
data.conditions # The policy conditions
```

### install

```
yarn add aleclarson/s3-post-policy#1.0.0
```
