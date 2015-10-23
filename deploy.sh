#!/bin/bash

# Check if the AWS CLI is in the PATH
found=$(which aws)
if [ -z "$found" ]; then
  echo "Please install the AWS CLI under your PATH: http://aws.amazon.com/cli/"
  exit 1
fi

# Check if jq is in the PATH
found=$(which jq)
if [ -z "$found" ]; then
  echo "Please install jq under your PATH: http://stedolan.github.io/jq/"
  exit 1
fi

# Read other configuration from config.json
REGION=$(jq -r '.REGION' config.json)
CLI_PROFILE=$(jq -r '.CLI_PROFILE' config.json)
BUCKET=$(jq -r '.BUCKET' config.json)
MAX_AGE=$(jq -r '.MAX_AGE' config.json)
IDENTITY_POOL_ID=$(jq -r '.IDENTITY_POOL_ID' config.json)
DEVELOPER_PROVIDER_NAME=$(jq -r '.DEVELOPER_PROVIDER_NAME' config.json)

#if a CLI Profile name is provided... use it.
if [[ ! -z "$CLI_PROFILE" ]]; then
  echo "setting session CLI profile to $CLI_PROFILE"
  export AWS_DEFAULT_PROFILE=$CLI_PROFILE
fi

# Updating Lambda functions
for f in $(ls -1); do
  if [[ $f != LambdaEncode* ]]; then
    continue
  fi
  echo "Updating function $f begin..."
	cp config.json $f/
  cd $f

  zip -r $f.zip index.js config.json
  aws lambda update-function-code --function-name ${f} --zip-file fileb://${f}.zip --region $REGION
	rm config.json
	rm $f.zip
  cd ..
  echo "Updating function $f end"
done

echo "Updating www content begin..."

cd www
if [ -d "edit" ]; then
  rm edit/*
else
  mkdir edit
fi

for f in $(ls -1 *{*.html,*.css,*.js}); do
  echo "Updating $f begin..."
  sed -e "s/<REGION>/$REGION/g" \
      -e "s/<IDENTITY_POOL_ID>/$IDENTITY_POOL_ID/g" \
      -e "s/<BUCKET>/$BUCKET/g" \
      -e "s/<DEVELOPER_PROVIDER_NAME>/$DEVELOPER_PROVIDER_NAME/g" \
      $f > edit/$f
  echo "Updating $f end"
done
echo "Updating www content end"
echo "Sync www content with S3 bucket $BUCKET begin..."
cd edit
aws s3 sync . s3://$BUCKET --cache-control max-age="$MAX_AGE" --acl public-read
cd ..
aws s3 cp momovi.com-hls-video-player s3://$BUCKET/momovi.com-hls-video-player --recursive --cache-control max-age="$MAX_AGE" --acl public-read
aws s3 cp logo s3://$BUCKET/logo --recursive --cache-control max-age="$MAX_AGE" --acl public-read
#cd ../..
cd ../
echo "Sync www content with S3 bucket $BUCKET end"
