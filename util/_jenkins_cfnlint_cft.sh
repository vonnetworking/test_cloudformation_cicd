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
CFNLINT_TMP="./cfnlint-tmp"
mkdir ${CFNLINT_TMP}
for F in `ls ./stage/*.zip`; do
  unzip -j ${F} -d ${CFNLINT_TMP}
done
cd ${CFNLINT_TMP}

for F in `find . -name *.yaml`; do
  echo "Running cfnlint on: ${F}"
  /usr/local/bin/cfn-lint -r us-east-1,us-east-2 --format=json --info ${F}

  if [ $? -eq 0 ]; then
    echo "cfnlint completed successfully on ${F}"
    exit 0
  else
    echo "cfnlint FAILED on ${F} exitting status 1..."
    exit 1
  fi
done
