console.log('Loading function');

var AWS = require('aws-sdk');
var s3 = new AWS.S3();
var config = require('./config.json');

function getExtension(path) {
   return path.split('.')[1];
}

function getMediaDir(path) {
   return path.split('/')[1];
}

function getMediaManifest(path) {

   return path.split('/')[0] + "/" + path.split('/')[1] + "/index.m3u8";
}

exports.handler = function(event, context) {

	var a = s3.listObjects({ Bucket: config.BUCKET, Prefix: "transcoder/" }, function(err, data) {
	  if (err) {
	      console.log("list error", err);
	      context.done('error', "error: " + err);
	      return;
	  }
	  // success case
	  console.log("got list data"); //, data);
	  if (! data ) {
			  console.log("no data...");
	      context.done('error', "empty list, outta.");
	      return;
	  }

		var arr = [];
		for (var i = 0; i < data.Contents.length; i++) {
        //console.log("item:", data.Contents[i].Key);
				//console.log("file ext:", getExtension(data.Contents[i].Key));
				if(getExtension(data.Contents[i].Key) == "png" && data.Contents[i].Key.indexOf("th_00001") >= 0){
					var obj = { link: data.Contents[i].Key, playlist: getMediaManifest(data.Contents[i].Key) };
					arr.push(obj);
				}
      }

		context.succeed({
			Media: arr
		});

	});

}
