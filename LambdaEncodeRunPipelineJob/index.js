var aws = require('aws-sdk');
var elastictranscoder = new aws.ElasticTranscoder();

// return basename without extension
function basename(path) {
   return path.split('/').reverse()[0].split('.')[0].replace("upload/", "");
}

function outputKey(name, ext) {
   //return name + '-' + Date.now().toString() + '.' + ext;
   return name + '.' + ext;
}

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    //http://docs.aws.amazon.com/elastictranscoder/latest/developerguide/create-job.html
    // Get the object from the event and show its content type
    var key = event.Records[0].s3.object.key;

    console.log("test1:", key);
    console.log("test2:", basename(key));

    var params = {
      Input: {
        Key: key
      },
      PipelineId: '1445378011103-dz113l',
      OutputKeyPrefix: 'transcoder/' + basename(key) + "/",
      Outputs: [
        {
          Key: basename(key) + "_400k", //HLS HLS 1M
          ThumbnailPattern: basename(key) + '_th_{count}',
          SegmentDuration:"5",
          PresetId: '1351620000001-200050', // h264
          Watermarks:[
             {
                InputKey:"logo/aws_logo_105x39.png",
                PresetWatermarkId:"BottomRight"
             }
          ],
        },
        {
          Key: basename(key) + "_1M", //HLS HLS 1M
          SegmentDuration:"5",
          PresetId: '1351620000001-200030', // h264
          Watermarks:[
             {
                InputKey:"logo/aws_logo_105x39.png",
                PresetWatermarkId:"BottomRight"
             }
          ],
        }
      ],
      "Playlists":[
         {
            "Format":"HLSv3",
            "Name":"index",
            "OutputKeys": [
              basename(key) + "_400k",
              basename(key) + "_1M"
            ]
         }
      ]
    };

    elastictranscoder.createJob(params, function(err, data) {
      if (err){
        console.log(err, err.stack); // an error occurred
        context.fail();
        return;
      }
      context.succeed();
    });
};
