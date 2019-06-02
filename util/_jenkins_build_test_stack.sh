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

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

BUILD_TIMEOUT=600
function sync_code () {
  #grab the prod bucket and sync it to a staging bucket
  #then overlay the code we want to test and build based on that

  echo "Syncing code for ${ZIP_TO_TEST}"

  /usr/local/bin/aws s3 sync ${AWS_PROD_CFT_S3_BUCKET} ${AWS_STAGE_CFT_S3_BUCKET}
  mkdir -p sync
  unzip -o ${ZIP_TO_TEST} -d sync
  cd sync
  export CLOUDFORMATION=$(ls */*.yaml)
  export CLOUDFORMATION_TEST_PARAMS=$(ls -1 params/*params.json)
  echo $CLOUDFORMATION_TEST_PARAMS

  /usr/local/bin/aws s3 sync . $AWS_STAGE_CFT_S3_BUCKET

  cd .. #move back up a level as syncing in complete
}

function cleanup () {
  echo "I would cleanup now..."
  rm -rf ./sync
}

function build_stack () {

  /usr/local/bin/aws cloudformation create-stack \
  --stack-name="$STACKNAME" \
  --template-url="${AWS_S3_ROOT_URL}/stage/${CLOUDFORMATION}" \
  --parameters="file://./sync/${CLOUDFORMATION_TEST_PARAMS}" > ./build_stack.out

  RESULT=$?

  #trim down command output to JUST the stackid
  STACKID=`cat './build_stack.out' | sed 's/}//g' | grep StackId \
  | awk -F'\"StackId\": ' '{print $2}' | sed 's/"//g'`

  echo "${RESULT}" "${STACKID}"
}

function wait_for_build () {
  TIMER=0
  INTERVAL=5
  while true; do
    /usr/local/bin/aws cloudformation describe-stacks \
    --stack-name ${STACKID} | grep "CREATE_COMPLETE"
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
  for F in `ls ./stage/*.zip`; do
    ZIP_TO_TEST=${F}
    PREFIX=`echo ${F} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}'`
    echo "prefix: " ${PREFIX}
    echo "zip to test: " ${ZIP_TO_TEST}
    STACKNAME=`echo TestStack-${BUILD_NUMBER}-${PREFIX}`
    sync_code
    read RESULT STACKID < <(build_stack)

    if [ $RESULT -ne 0 ]; then
      exit $RESULT
    fi
    echo ${STACKID}
    echo ${STACKID} > ./${PREFIX}.stackid.out #write stack id out to placeholder file
    echo "Starting build of stack: ${STACKID}..."

    echo "Waiting up to ${BUILD_TIMEOUT} seconds for stack build to complete..."

    wait_for_build

    cleanup
  done
}

main
