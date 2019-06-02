#!/usr/bin/env bash

############################################################################
###                 _jenkins_publish_to_prod.sh
###
### Description: wrapper for publishing tested artifacts to prod S3 bucket paths
###
### Usage:
###	    _jenkins_publish_to_prod.sh
###
###     ::ENV::
###     This script requires the following environment variables
###     CLOUDFORMATION - string - path to cloudformation that should have
###                               cfnlint run against it
###     AWS_PROD_CFT_S3_BUCKET - jenkins cred - s3 path (without trailing slash)
###                                             which serves as root path to
###                                             publish to
###     ::PARAMS::
###       script takes no parameters, but expects certain environ var(s)
###
###     ::RETURNS::
###       success|failure - success exit code 0, fail exit code 1
###
############################################################################

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin


/usr/local/bin/aws s3 cp ${CLOUDFORMATION} ${AWS_PROD_CFT_S3_BUCKET}/${CLOUDFORMATION}

if [ $? -eq 0 ]; then
  echo "success"
  exit 0
else
  echo "failure"
  exit 1
fi
