#!/usr/bin/env bash

############################################################################
###                 _jenkins_delete_test_stack.sh
###
### Description: wrapper for the aws delete-stack command returning success
### 		 or failure of delete-stack command
###
### Usage:
###	    _jenkins_delete_test_stack.sh
###
###     ::PARAMS::
###       script takes no parameters, but expects a $BUILD_NUMBER_stackid.out
###       file to exist IN CURRENT DIRECTORY
###     ::RETURNS::
###       success|failure - success exit code 0, fail exit code 1
###
############################################################################

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

DELETE_TIMEOUT=600
INTERVAL=10

function delete_stack () {
  for F in `ls -1 ./*.stackid.out`; do
    /usr/local/bin/aws cloudformation delete-stack --stack-name `cat ${F}`
    if [ $? -ne 0 ]; then

      echo "failed to delete test stack..."
      echo "Stack may require manual cleanup"
      echo "Stack ID: " `cat ${F}`

      exit 1
    fi
  done
}

function wait_for_delete () {
  TIMER=0
  cat ./*.stackid.out > ./all.stackids.out
  while true; do
    /usr/local/bin/aws cloudformation list-stacks --stack-status-filter=DELETE_COMPLETE | grep -f ./all.stackids.out
    if [ $? -eq 0 ]; then
      exit 0
    else
      if [ $TIMER -ge $DELETE_TIMEOUT ]; then
        echo "Delete stack timer of $DELETE_TIMEOUT sec expired..."
        echo "Stack may require manual cleanup"
        echo "Stack IDs: " `cat ./*.stackid.out`
        exit 1
      fi

      sleep $INTERVAL
      TIMER=$(echo "$TIMER+$INTERVAL" | bc)
    fi
  done
}

function main () {

  #basic check that stackid is available
  grep aws ./*.stackid.out
  if [ $? -ne 0 ]; then
    exit 1
  fi

  delete_stack
  wait_for_delete
}

main
