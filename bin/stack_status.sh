#!/bin/bash

pollStatus=$1
stackName=${2:-$STACK_NAME}
interval=${3:-5}
stackFlag=${stackName:+ --stack-name $stackName}

awsCommand="aws cloudformation describe-stacks$stackFlag --output json"

if [ -z "$pollStatus" ]; then
    $awsCommand | jq ".Stacks[] | { StackName, StackStatus }"
else
    pollStatus=${pollStatus^^}
    echo Polling $stackName for status $pollStatus
    stackStatus=
    while true; do
        stackStatus=$($awsCommand | jq -r ".Stacks[0].StackStatus")
        echo $(date +%Y-%m-%d:%H:%M:%S): $stackStatus
        if [ "${stackStatus%$pollStatus}" != "$stackStatus" ]; then
            break
        fi
        sleep $interval
    done
fi
