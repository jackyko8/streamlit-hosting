#!/bin/bash

# Build script for Streamlit app


############################################################
#
# Initialisation
#

defaultDeployS3Key=src/streamlit

USAGE=$(cat <<EOD
Usage: $(basename $0) [-?dcuCU] [-p aws_profile] [-s s3_bucket] [stack_name:-STACK_NAME]
    Build Streamlit functions from local IDE, serving as a reference to pipeline integration
    1. Check which Streamlit functions or common files have changed
    2. Create the zip files for updated Streamlit functions
    3. Upload created zip files to S3

    stack_name  The name of the stack to build
    -p profile  AWS Profile to use
                    default to "\$AWS_PROFILE" if defined else "default"
    -s s3_path  S3 bucket the zip files uploaded to
                    default to "\$S3_PATH" if defined else
                        "s3://<stack_name>-deployment-<aws_account>/$defaultDeployS3Key"
    -d          Deploy Streamlit functions after zip files uploaded to S3
    -u          Update CloudFormation stack as the final step
    -c          Create CloudFormation stack as the final step
    -U          Update CloudFormation stack only (without deploying Streamlit)
    -C          Create CloudFormation stack only (without deploying Streamlit)
    -?          Help
    Note:
      If both -u and -c are specified, the last one will prevail,
      and will be done after Streamlit deployment if required.
EOD
)
usage() { echo -e "$USAGE" >&2; exit 2; }

error() { echo "$1" >&2; exit 1; }

TEMPDIR=$(mktemp -d)
trap 'rm -rf -- "$TEMPDIR"' EXIT

doDeployStreamlit=
doCfn=
skipStreamlit=
s3Path=
while getopts "?dcuCUp:s:" arg; do
    case "$arg" in
        d)  doDeployStreamlit=on;;
        C)  doCfn=create;;
        U)  doCfn=update;;
        c)  doCfn=create; skipStreamlit=on;;
        u)  doCfn=update; skipStreamlit=on;;
        p)  profile=$OPTARG;;
        s)  s3Path=$OPTARG;;
        *)  usage;;
    esac
done
shift $((OPTIND-1))

stackName=${1:-$STACK_NAME}
if [ -z "$stackName" ]; then
    usage
fi

profile=${profile:-${AWS_PROFILE:-default}}
awsAccount=$(aws sts get-caller-identity --profile $profile --output json | jq -r .Account)
export AWS_DEFAULT_OUTPUT=json

s3Path=${s3Path:-${S3_PATH:-${stackName}-deployment-$awsAccount/$defaultDeployS3Key}}
s3Path=${s3Path#s3://}
deployS3Bucket=${s3Path%%/*}
deployS3Key=${s3Path#*/}

srcDir=./src
bnStreamlit=app
bnCfn=cfn
srcStreamlit=$srcDir/$bnStreamlit
srcCfn=$srcDir/$bnCfn
buildDir=./build
cfnTemplate=$srcCfn/${stackName}.yml
paramsFile=$srcCfn/params-${stackName}.json

echoDivider="========================================"

cat <<- EOD
stackName=$stackName
profile=$profile
awsAccount=$awsAccount
s3Path=s3://$s3Path
deployS3Bucket=$deployS3Bucket
deployS3Key=$deployS3Key
srcDir=$srcDir
srcStreamlit=$srcStreamlit
buildDir=$buildDir
cfnTemplate=$cfnTemplate
doDeployStreamlit=$doDeployStreamlit
doCfn=$doCfn
EOD


if [ ! -d $buildDir ]; then
    echo "Warning: Build Directory does not exist: $buildDir" >&2
    mkdir -p $buildDir
    echo "Created Build Directory: $buildDir" >&2
fi


############################################################
#
# Check if there are changes in Streamlit code
# and create zip files if the code has changed
#

zipName=$bnStreamlit.zip

newestStreamlit=$(find $srcStreamlit -type f -name "*.py" -o -name "*.txt" -o -name "*.sh" | xargs ls -t 2> /dev/null | head -n1)
streamlitUpdated=
if [ ! -f "$buildDir/$zipName" -o "$buildDir/$zipName" -ot "$newestStreamlit" ]; then
    # If zip file does not exist or is older than the src
    streamlitUpdated=true
fi

if [ -z "$streamlitUpdated" ]; then
    echo $streamlitName is up to date
else
    echo $streamlitName needs update
    (cd $srcStreamlit; zip -r $TEMPDIR/$zipName *.py *.sh config)
    mv $TEMPDIR/$zipName $buildDir/$zipName
fi

# If Streamlit updated or CloudFormation to create/update (useful for new environment deployment)
if [ -n "$streamlitUpdated" ]; then
    aws s3 cp --profile $profile $buildDir/$zipName s3://$deployS3Bucket/$deployS3Key/$zipName
    test $? -eq 0 || error "Line $LINENO"
fi

if [ -n "$doCfn" ]; then
    echo $echoDivider
    aws cloudformation ${doCfn}-stack \
        --profile $profile \
        --stack-name ${stackName} \
        --template-body file://$cfnTemplate \
        --parameters file://$paramsFile \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
    test $? -eq 0 || error "Line $LINENO"
fi

echo $echoDivider
