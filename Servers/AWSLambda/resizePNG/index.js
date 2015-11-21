var async = require('async'),
		gm = require('gm').subClass({imageMagick: true}),
		s3 = new (require('aws-sdk')).S3(),
		util = require('util')

// constants
var MAX_WIDTH  = 100
var MAX_HEIGHT = 100

// Confirm 2048px max

// Resize to 309px-@3x & 186px-@2x

// get reference to S3 client
var s3 = new aws.S3()

exports.handler = function(event, context) {
	// Read options from the event.
	console.log("Reading options from event:\n", util.inspect(event, {depth: 5}))
	var srcBucket = event.Records[0].s3.bucket.name
	// Object key may have spaces or unicode non-ASCII characters.
    var srcKey    =
    decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "))
	var dstBucket = srcBucket + "resized"
	var dstKey    = "resized-" + srcKey

	// Sanity check: validate that source and destination are different buckets.
	if (srcBucket == dstBucket) {
		console.error("Destination bucket must not match source bucket.")
		return
	}

	// Infer the image type.
	var imageType = "jpg"

	// Download the image from S3, transform, and upload to a different S3 bucket.
	async.waterfall([
		function download(next) {
			// Download the image from S3 into a buffer.
			s3.getObject({
					Bucket: srcBucket,
					Key: srcKey
				},
				next)
			},
		function transform(response, next) {
			gm(response.Body).size(function(err, size) {
				// Infer the scaling factor to avoid stretching the image unnaturally.
				var scalingFactor = Math.min(
					MAX_WIDTH / size.width,
					MAX_HEIGHT / size.height
				)
				var width  = scalingFactor * size.width
				var height = scalingFactor * size.height

				// Transform the image buffer in memory.
				this.resize(width, height)
					.toBuffer(imageType, function(err, buffer) {
						if (err) {
							next(err)
						} else {
							next(null, response.ContentType, buffer)
						}
					})
			})
		},
		function upload(contentType, data, next) {
			// Stream the transformed image to a different S3 bucket.
			s3.putObject({
					Bucket: dstBucket,
					Key: dstKey,
					Body: data,
					ContentType: contentType
				},
				next)
			}
		], function (err) {
			if (err) {
				console.error(
					'Unable to resize ' + srcBucket + '/' + srcKey +
					' and upload to ' + dstBucket + '/' + dstKey +
					' due to an error: ' + err
				)
			} else {
				console.log(
					'Successfully resized ' + srcBucket + '/' + srcKey +
					' and uploaded to ' + dstBucket + '/' + dstKey
				)
			}

			context.done()
		}
	)
}
