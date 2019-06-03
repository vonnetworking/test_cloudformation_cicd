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
IFS=$'\n'
CFNLINT_TMP="./cfnlint-tmp"
if [ ! -d ${CFNLINT_TMP} ]; then
  mkdir ${CFNLINT_TMP}
fi


for F in `ls ./stage/*.zip`; do
  unzip -o -j ${F} -d ${CFNLINT_TMP}
done
cd ${CFNLINT_TMP}

RESULT=0 #Assume success
for F in `ls -1 *.yaml`; do
  echo "Running cfnlint on: ${F}"
  /usr/local/bin/cfn-lint -r us-east-1,us-east-2 --format=json --info ${F}

  if [ $? -eq 0 ]; then
    if [ $RESULT -eq 1]; then
      RESULT=1
    echo "cfnlint completed successfully on ${F}"
  else
    RESULT=1
  fi
done

exit $RESULT
