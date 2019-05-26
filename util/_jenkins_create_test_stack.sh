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
###     ::PARAMS::
###       script takes 2 positional arguments; respectively, they are
###         $1 - Stack-Name = name of the stack to be generate
###         $2 - Cloudformation = path to yaml to be built
###         $2 - parameters_file.json = path to the parameters file to be used
###              to create the stack in AWS
###
###     ::RETURNS::
###       $STACKID = AWS Arn for the newly created stack for reference
###
############################################################################

#set commandline args as globals
#TODO - get these more localized - not a fan of this layout
STACKNAME=$1
CLOUDFORMATION=$2
BUILDPARAMS=$3


function build_stack () {

   /usr/local/bin/aws cloudformation create-stack \
  --stack-name="$STACKNAME" \
  --template-body="file://$CLOUDFORMATION" \
  --parameters="file://$BUILDPARAMS" \
  | sed 's/}//g' | sed 's/"//g' | grep StackId | awk -F'\"StackId\": ' '{print $2}'

}

function main () {
  STACKID=$(build_stack)
  echo ${STACKID}
}

main
