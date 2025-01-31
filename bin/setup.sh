#!/bin/bash

# Use `source bin/setup.sh` from the repo root to set these environment variables

############################################################
#
# Define the STACK_NAME by uncommenting one of the followings
#

# Uncomment this line to create a stack to host on ALB
export STACK_NAME=streamlit-app-alb

# Uncomment this line to create a stack to host on CloudFormation
# export STACK_NAME=streamlit-app-cfn

#
############################################################

# Deployment S3 Path
export S3_PATH=streamlit-hosting-deployment-309062441977/src/streamlit

# For pip installs
export TMPDIR=$(pwd)/_tmp
test ! -d $TMPDIR && mkdir -p $TMPDIR
