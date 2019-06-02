#!/usr/bin/env bash

############################################################################
###                 _jenkins_cfn_nag_scan.sh
###
### Description: wrapper for cfn_nag_scan command returning success
### 		 or failure of cfnlint command
###
### Usage:
###	    _jenkins_cfn_nag_scan.sh
###
###     ::ENV::
###     This script requires the following environment variables
###     CLOUDFORMATION - string - path to cloudformation that should have
###                               cfnlint run against it
###     CLOUDFORMATION_TEST_PARAMS - string - path to cloudformation parameter
###                                           file that should be used when
###                                           scanning CLOUDFORMATION
###     ::PARAMS::
###       script takes no parameters, but expects certain environ var(s)
###
###     ::RETURNS::
###       success|failure - success exit code 0, fail exit code 1
###
############################################################################

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

/usr/local/bin/cfn_nag_scan \
--input-path $CLOUDFORMATION \
--parameter-values-path=$CLOUDFORMATION_TEST_PARAMS
#--profile-path='./util/.cfn_nagrc'

if [ $? -eq 0 ]; then
  echo "success"
  exit 0
else
  echo "failure"
  exit 1
fi
