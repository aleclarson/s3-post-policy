
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

# Expose all options as values.
type.defineValues (options) -> options

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
    conditions.push ["starts-with", "$Content-Type", @contentType or ""]
    conditions.push ["starts-with", "$Content-Length", ""]

    # File name restriction (supports starts-with matching for partial keys)
    if @key and (not @key.endsWith "/") and (not @key.endsWith "-")
    then conditions.push {@key}
    else conditions.push ["starts-with", "$key", @key or ""]

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
      date: Date.Maybe
      expires: Number.Maybe
      accessKeyId: String
      secretAccessKey: String

    return (options) ->
      assertTypes options, optionTypes

      options.date ?= new Date
      date = options.date.toISOString().replace /[:\-]|\.\d{3}/g, ""

      options.expires ?= 30 # minutes
      expires = new Date (6e4 * options.expires) + options.date.getTime()
      expiration = expires.toISOString()

      conditions = @_createConditions()
      conditions.push {"x-amz-date": date}

      credential = "#{options.accessKeyId}/#{date.substr 0, 8}/#{options.region}/s3/aws4_request"
      conditions.push {"x-amz-credential": credential}

      policy = JSON.stringify {expiration, conditions}
      policy = (new Buffer policy).toString "base64"

      signature = aws4_sign options.secretAccessKey, options.date, @region, "s3", policy
      return {policy, signature, credential, date}

module.exports = type.build()
