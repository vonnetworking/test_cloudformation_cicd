#!/usr/bin/env bash

############################################################################
###                 _jenkins_cfnlint_cft.sh
###
### Description: wrapper for cfnlint command returning success
### 		 or failure of cfnlint command
###
### Usage:
###	    _jenkins_cfnlint_cft.sh
###
###     ::ENV::
###     This script requires the following environment variables
###     CLOUDFORMATION - string - path to cloudformation that should have
###                               cfnlint run against it
###     ::PARAMS::
###       script takes no parameters, but expects certain environ var(s)
###
###     ::RETURNS::
###       success|failure - success exit code 0, fail exit code 1
###
############################################################################

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

/usr/local/bin/cfn-lint -r us-east-1,us-east-2 --list-rules --format=json --info $CLOUDFORMATION

if [ $? -eq 0 ]; then
  echo "success"
  exit 0
else
  echo "failure"
  exit 1
fi
