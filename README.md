# LambdaEncode

Simple S3 hosted website that allows you to upload a video to S3. The video will then be encoded using HLS adaptive bit rate by Amazon Elastic Transcoder automatically using a Lambda triggered function. 

## Installation

A sample installation script using Bash (`init.sh`) is provided to install and configure all necessary resources in your AWS account:

- the [Amazon S3](http://aws.amazon.com/s3/) bucket to host the sample HTML pages
- the [AWS Identity and Access Management (IAM)](http://aws.amazon.com/iam/) roles for Amazon Cognito and AWS Lambda
- the [Amazon Cognito](http://aws.amazon.com/cognito/) identity pool
- the [AWS Lambda](http://aws.amazon.com/lambda/) functions

The `init.sh` script requires a configured [AWS Command Line Interface (CLI)](http://aws.amazon.com/cli/) and the [jq](http://stedolan.github.io/jq/) tool. The script is designed to be non destructive, so you can run it again (e.g. if you delete a role) without affecting the other resources.

**Before running the `init.sh` script, set up your configuration in the `config.json` file**:

- your AWS account (12-digit number)
- the AWS region (e.g. "us-east-1")
- the Amazon S3 bucket to use for the sample HTML pages
...

```json
{
  "AWS_ACCOUNT_ID": "123412341234",
  "REGION": "us-east-1",
  "BUCKET": "bucket",
  "IDENTITY_POOL_NAME": "LambdaEncode",
  ...
}
```

At the end of the `init.sh` script, you can start creating users pointing your browser to your bucket's web endpoint.

**Manual Steps:**
The (`init.sh`) bash script does almost everything, but there are a few manual steps.
- Create the Amazon Elastic Transcoder Pipleline
- Add the pipeline id to appropriate preset id's to Lambda function LambdaEncodeRunPipelineJob
- Add the event source to Lambda function LambdaEncodeRunPipelineJob



