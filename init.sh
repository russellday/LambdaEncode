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
AWS_ACCOUNT_ID=$(jq -r '.AWS_ACCOUNT_ID' config.json)
CLI_PROFILE=$(jq -r '.CLI_PROFILE' config.json)
REGION=$(jq -r '.REGION' config.json)
BUCKET=$(jq -r '.BUCKET' config.json)
ALLOWED_ORIGIN=$(jq -r '.ALLOWED_ORIGIN' config.json)
MAX_AGE=$(jq -r '.MAX_AGE' config.json)
IDENTITY_POOL_NAME=$(jq -r '.IDENTITY_POOL_NAME' config.json)
DEVELOPER_PROVIDER_NAME=$(jq -r '.DEVELOPER_PROVIDER_NAME' config.json)

#if a CLI Profile name is provided... use it.
if [[ ! -z "$CLI_PROFILE" ]]; then
  echo "setting session CLI profile to $CLI_PROFILE"
  export AWS_DEFAULT_PROFILE=$CLI_PROFILE
fi

# Create S3 Bucket
aws s3 mb s3://$BUCKET

rm cors.edit.json
cp cors.json cors.edit.json
sed -i -- "s|<ALLOWED_ORIGIN>|$ALLOWED_ORIGIN|g" cors.edit.json
aws s3api put-bucket-cors --bucket $BUCKET --cors-configuration file://cors.edit.json
rm cors.edit.json

sleep 1 # To avoid errors

aws s3 website s3://$BUCKET/ --index-document index.html

# todo's:
# automate the following:

# https://forums.aws.amazon.com/thread.jspa?threadID=182758
# debug: trying to automate associating the event with the lambda function
# getting error: A client error (InvalidArgument) occurred when calling the PutBucketNotification operation: Unable to validate the following destination configurations
# i'm sure i am doing something stupid...
# https://github.com/brettweavnet/cloud-trail-notifier
# https://alestic.com/2014/11/aws-lambda-cli/


# aws iam create-role --role-name "jiveass1" --assume-role-policy-document file://test2.json
# aws iam put-role-policy --role-name "jiveass1" --policy-name "jiveass1_policy" --policy-document file://test3.json
#aws s3api put-bucket-notification-configuration --bucket $BUCKET --notification-configuration file://test.json --debug

#exit;

#Create the pipleine...
# aws elastictranscoder create-pipeline --name TestPipe1 --input-bucket $BUCKET --output-bucket $BUCKET --role "arn:aws:iam::831402888584:role/Elastic_Transcoder_Default_Role"

# Create Cognito Identity Pool
IDENTITY_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 1 \
	  --query 'IdentityPools[?IdentityPoolName == `'$IDENTITY_POOL_NAME'`].IdentityPoolId' \
	  --output text --region $REGION)
if [ -z "$IDENTITY_POOL_ID" ]; then
	echo "Creating Cognito Identity Pool $IDENTITY_POOL_NAME begin..."
	IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool --identity-pool-name $IDENTITY_POOL_NAME \
	    --allow-unauthenticated-identities --developer-provider-name $DEVELOPER_PROVIDER_NAME \
	    --query 'IdentityPoolId' --output text --region $REGION)
	echo "Identity Pool Id: $IDENTITY_POOL_ID"
	echo "Creating Cognito Identity Pool $IDENTITY_POOL_NAME end"
else
  echo "Using previous identity pool with name $IDENTITY_POOL_NAME and id $IDENTITY_POOL_ID"
fi

# Updating Cognito Identity Pool Id in the configuration file
mv config.json config.json.orig
jq '.IDENTITY_POOL_ID="'"$IDENTITY_POOL_ID"'"' config.json.orig > config.json
rm config.json.orig


cd iam
if [ -d "edit" ]; then
  rm edit/*
else
  mkdir edit
fi

# Create IAM Roles for Cognito
for f in $(ls -1 trust*); do
  echo "Editing trust from $f begin..."
  sed -e "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" \
      -e "s/<DYNAMODB_TABLE>/$DDB_TABLE/g" \
      -e "s/<DYNAMODB_EMAIL_INDEX>/$DDB_EMAIL_INDEX/g" \
      -e "s/<IDENTITY_POOL_ID>/$IDENTITY_POOL_ID/g" \
      -e "s/<REGION>/$REGION/g" \
      $f > edit/$f
  echo "Editing trust from $f end"
done
for f in $(ls -1 Cognito*); do
  role="${f%.*}"
  echo "Creating role $role from $f begin..."
  sed -e "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" \
      -e "s/<DYNAMODB_TABLE>/$DDB_TABLE/g" \
      -e "s/<BUCKET>/$BUCKET/g" \
      -e "s/<DYNAMODB_EMAIL_INDEX>/$DDB_EMAIL_INDEX/g" \
      -e "s/<REGION>/$REGION/g" \
      -e "s/<IDENTITY_POOL_ID>/$IDENTITY_POOL_ID/g" \
      -e "s/<REGION>/$REGION/g" \
	      $f > edit/$f
  if [[ $f == *Unauth_* ]]; then
    trust="trust_policy_cognito_unauth.json"
    unauthRole="$role"
  else
    trust="trust_policy_cognito_auth.json"
    authRole="$role"
  fi
  aws iam create-role --role-name $role --assume-role-policy-document file://edit/$trust
  aws iam update-assume-role-policy --role-name $role --policy-document file://edit/$trust
  aws iam put-role-policy --role-name $role --policy-name $role --policy-document file://edit/$f
  echo "Creating role $role end"
done
echo "Setting identity pool roles begin..."
roles='{"unauthenticated":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/'"$unauthRole"'","authenticated":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/'"$authRole"'"}'
echo "Roles: $roles"
aws cognito-identity set-identity-pool-roles \
  --identity-pool-id $IDENTITY_POOL_ID \
  --roles $roles \
  --region $REGION
echo "Setting identity pool roles end"

# Create IAM Roles for Lambda Function
for f in $(ls -1 Lambda*); do
  role="${f%.*}"
  echo "Creating role $role from $f begin..."
  sed -e "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" \
      -e "s/<IDENTITY_POOL_ID>/$IDENTITY_POOL_ID/g" \
      -e "s/<REGION>/$REGION/g" \
      -e "s/<BUCKET>/$BUCKET/g" \
      $f > edit/$f
	trust="trust_policy_lambda.json"
  aws iam create-role --role-name $role --assume-role-policy-document file://edit/$trust
  aws iam update-assume-role-policy --role-name $role --policy-document file://edit/$trust
  aws iam put-role-policy --role-name $role --policy-name $role --policy-document file://edit/$f
  echo "Creating role $role end"
done

cd ..

# Create Lambda Functions
for f in $(ls -1|grep ^LambdaEncode); do
  echo "Creating function $f begin..."
  cp config.json $f/
  cd $f
  zip -r $f.zip index.js config.json
  aws lambda create-function --function-name ${f} \
      --runtime nodejs \
      --role arn:aws:iam::$AWS_ACCOUNT_ID:role/${f} \
      --handler index.handler \
      --zip-file fileb://${f}.zip \
	  	--region $REGION
	sleep 1 # To avoid errors
  cd ..
  echo "Creating function $f end"
done

./deploy.sh
