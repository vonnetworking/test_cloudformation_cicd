#!/usr/bin/env bash

############################################################################
###                 _jenkins_create_test_stack.sh
###
### Description: wrapper for the aws create-stack command returning JUST the
### 		 StackId, for use in further stages of the Jenkins Iac Pipeline
###
### Usage:
###	    _jenkins_create_test_stack.sh <Stack-Name> <Cloudformation> <parameters_file.json>
###
###     ::ENV::
###     This script requires the following environment variables
###         $STACKNAME - Stack-Name = name of the stack to be generate
###         $CLOUDFORMATION - Cloudformation = path to yaml to be built
###         $CLOUDFORMATION_TEST_PARAMS - parameters_file.json = path to the
###                                       parameters file to be used
###                                       to create the stack in AWS
###     ::PARAMS::
###       script takes no parameters, but expects certain environ var(s)
###
###     ::RETURNS::
###       $STACKID = AWS Arn for the newly created stack for reference
###
############################################################################

BUILD_TIMEOUT=600

function build_stack () {

   /usr/local/bin/aws cloudformation create-stack \
  --stack-name="$STACKNAME" \
  --template-body="file://$CLOUDFORMATION" \
  --parameters="file://$CLOUDFORMATION_TEST_PARAMS" > './build_stack.out'

  RESULT=$?
  #trim down command output to JUST the stackid
  STACKID=`cat './build_stack.out' | sed 's/}//g' | grep StackId \
  | awk -F'\"StackId\": ' '{print $2}' | sed 's/"//g'`


  echo "${RESULT}" "$STACKID"
}

function wait_for_build () {
  TIMER=0
  INTERVAL=10
  while true; do
    /usr/local/bin/aws cloudformation describe-stacks --stack-name ${STACKID} | grep "CREATE_COMPLETE"
    if [ $? -eq 0 ]; then
      break
    else #increase the timer by the interval after sleeping for interval
      if [ $TIMER -ge $BUILD_TIMEOUT ]; then
        echo "BUILD TIMEOUT EXPIRED! - ${BUILD_TIMEOUT} seconds exceeded"
        exit 2
      fi
      sleep $INTERVAL
      TIMER=$(echo "$TIMER+$INTERVAL" | bc)
    fi
  done
}
function main () {
  read RESULT STACKID < <(build_stack)

  if [ $RESULT -ne 0 ]; then
    exit $RESULT
  fi
  echo ${STACKID} > ./stackid.out #write stack id out to placeholder file
  echo "Starting build of stack: ${STACKID}..."

  echo "Waiting up to $BUILD_TIMEOUT seconds for stack build to complete..."

  wait_for_build

  exit ${RESULT}
}

main