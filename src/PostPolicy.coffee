
assertTypes = require "assertTypes"
aws4_sign = require "aws4-signature"
isType = require "isType"
OneOf = require "OneOf"
Type = require "Type"

# Some values are not included: http://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
AccessControl = OneOf "private public-read public-read-write"

type = Type "PostPolicy"

type.defineOptions
  region: String.isRequired
  bucket: String.isRequired
  acl: AccessControl.isRequired
  key: String
  metadata: Object
  conditions: Array
  contentType: String
  contentLength: Number.or Array

type.defineValues (options) ->
  options.date = new Date
  options.expires = new Date options.expires
  return options

type.defineMethods

  _createConditions: ->

    conditions =
      if @conditions
      then @conditions.slice()
      else []

    # Exact matching
    conditions.push {@bucket}
    conditions.push {@acl}

    # Starts-with matching
    conditions.push ["starts-with", "$key", @key or ""]
    conditions.push ["starts-with", "$Content-Type", @contentType or ""]
    conditions.push ["starts-with", "$Content-Length", ""]

    # Limiting file size
    if @contentLength
      if isType @contentLength, Array
        conditions.push ["content-length-range", @contentLength[0], @contentLength[1]]
      else if isType @contentLength, Number
        conditions.push ["content-length-range", 1, @contentLength]

    # Custom name/value pairs
    if @metadata
      for name, value of @metadata
        assertType value, String, "metadata.#{name}"
        conditions.push {"x-amz-meta-#{name}": value}

    # Immutable conditions
    conditions.push {"x-amz-algorithm": "AWS4-HMAC-SHA256"}
    conditions.push {"x-amz-server-side-algorithm": "AES256"}
    conditions.push {"x-amz-storage-class": "STANDARD"}

    return conditions

  sign: do ->

    optionTypes =
      publicKey: String
      privateKey: String
      date: Date.Maybe
      expires: Number.Maybe

    return (options) ->
      assertTypes options, optionTypes
      options.date ?= new Date
      options.expires ?= 30 # minutes
      options.expires = new Date (6e4 * options.expires) + options.date.getTime()
      date = options.date.toISOString().replace /[:\-]|\.\d{3}/g, ""
      expiration = expires.toISOString()
      conditions = @_createConditions()
      conditions.push {"x-amz-date": date}
      conditions.push {"x-amz-credential": "#{options.publicKey}/#{date.substr 0, 8}/#{options.region}/s3/aws4_request"}
      policy = JSON.stringify {expiration, conditions}
      encoded = (new Buffer policy).toString "base64"
      signature = aws4_sign options.privateKey, options.date, @region, "s3", encoded
      return {encoded, signature}

module.exports = type.build()
