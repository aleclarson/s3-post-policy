var AccessControl, OneOf, Type, assertTypes, aws4_sign, isType, type;

assertTypes = require("assertTypes");

aws4_sign = require("aws4-signature");

isType = require("isType");

OneOf = require("OneOf");

Type = require("Type");

AccessControl = OneOf("private public-read public-read-write");

type = Type("PostPolicy");

type.defineOptions({
  region: String.isRequired,
  bucket: String.isRequired,
  acl: AccessControl.isRequired,
  key: String,
  metadata: Object,
  conditions: Array,
  contentType: String,
  contentLength: Number.or(Array)
});

type.defineValues(function(options) {
  options.date = new Date;
  options.expires = new Date(options.expires);
  return options;
});

type.defineMethods({
  _createConditions: function() {
    var conditions, name, obj, ref, value;
    conditions = this.conditions ? this.conditions.slice() : [];
    conditions.push({
      bucket: this.bucket
    });
    conditions.push({
      acl: this.acl
    });
    conditions.push(["starts-with", "$key", this.key || ""]);
    conditions.push(["starts-with", "$Content-Type", this.contentType || ""]);
    conditions.push(["starts-with", "$Content-Length", ""]);
    if (this.contentLength) {
      if (isType(this.contentLength, Array)) {
        conditions.push(["content-length-range", this.contentLength[0], this.contentLength[1]]);
      } else if (isType(this.contentLength, Number)) {
        conditions.push(["content-length-range", 1, this.contentLength]);
      }
    }
    if (this.metadata) {
      ref = this.metadata;
      for (name in ref) {
        value = ref[name];
        assertType(value, String, "metadata." + name);
        conditions.push((
          obj = {},
          obj["x-amz-meta-" + name] = value,
          obj
        ));
      }
    }
    conditions.push({
      "x-amz-algorithm": "AWS4-HMAC-SHA256"
    });
    conditions.push({
      "x-amz-server-side-algorithm": "AES256"
    });
    conditions.push({
      "x-amz-storage-class": "STANDARD"
    });
    return conditions;
  },
  sign: (function() {
    var optionTypes;
    optionTypes = {
      publicKey: String,
      privateKey: String,
      date: Date.Maybe,
      expires: Number.Maybe
    };
    return function(options) {
      var conditions, date, encoded, expiration, policy, signature;
      assertTypes(options, optionTypes);
      if (options.date == null) {
        options.date = new Date;
      }
      if (options.expires == null) {
        options.expires = 30;
      }
      options.expires = new Date((6e4 * options.expires) + options.date.getTime());
      date = options.date.toISOString().replace(/[:\-]|\.\d{3}/g, "");
      expiration = expires.toISOString();
      conditions = this._createConditions();
      conditions.push({
        "x-amz-date": date
      });
      conditions.push({
        "x-amz-credential": options.publicKey + "/" + (date.substr(0, 8)) + "/" + options.region + "/s3/aws4_request"
      });
      policy = JSON.stringify({
        expiration: expiration,
        conditions: conditions
      });
      encoded = (new Buffer(policy)).toString("base64");
      signature = aws4_sign(options.privateKey, options.date, this.region, "s3", encoded);
      return {
        encoded: encoded,
        signature: signature
      };
    };
  })()
});

module.exports = type.build();

//# sourceMappingURL=map/PostPolicy.map
