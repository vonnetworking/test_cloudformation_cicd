#!/usr/bin/env bash

############################################################################
###                 _jenkins_run_sec_scan.sh
###
### Description: wrapper for cloudsploit security scanner returning success
### 		 or failure based on clean bill of health for resources in built stack
###
### Usage:
###	    _jenkins_run_sec_scan.sh
###
###     ::ENV::
###     This script requires the following environment variables
###
###
###     ::PARAMS::
###       script takes no parameters, but expects certain environ var(s)
###
###     ::RETURNS::
###       success|failure - success exit code 0, fail exit code 1
###
############################################################################

PATH=$PATH:/usr/local/opt/python/bin:/usr/local/opt/python/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
GITURL='https://github.com/cloudsploit/scans.git'
CLOUDSPLOIT_DIR='./cloudsploit_security_scanner'

function install_cloudsploit () {

  rm -rf ${CLOUDSPLOIT_DIR}
  git clone ${GITURL} ${CLOUDSPLOIT_DIR}

  cd ${CLOUDSPLOIT_DIR}
  /usr/local/bin/npm install async > /dev/null 2>&1
  /usr/local/bin/npm install > /dev/null 2>&1
  /usr/local/bin/npm audit fix > /dev/null 2>&1
}

function setup_cloudsploit () {

  git apply ../util/cloudsploit.patch
}

function run_cloudsploit () {
  /usr/local/bin/node index.js --console --junit=../reports/sec_scan.xml > ../reports/cloudsploit_results.out || true
}

function check_results () {

  #This block generates a pass / fail based ONLY on the resources created
  # in the test build, that way if the account its being built into has issues
  # the dev doesn't get penalized.
  > ../stack_resources.out
  for F in `ls ../*.stackid.out`; do
    STACKNAME=`cat ${F}`
    /usr/local/bin/aws cloudformation list-stack-resources \
    --stack-name=${STACKNAME} \
    | grep "PhysicalResourceId" | awk -F ':' '{print $2}' | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' >> ../stack_resources.out
  done

  #Summarize results
  PASSED_TESTS=`grep -f ../stack_resources.out ../reports/cloudsploit_results.out | grep -c OK`

  #If there is a rule masking file, use it, otherwise, ignore and keep rolling
  MASK_FILE="../util/sec_scan.mask"
  if [ -f ${MASK_FILE} ]; then
    FAILED_TESTS=`grep -f ../stack_resources.out ../reports/cloudsploit_results.out | grep -vf ${MASK_FILE} | grep -c FAIL`
    MASKED_TESTS=`grep -v '#' ${MASK_FILE} | wc -l | awk '{print $1}'`
  else
    FAILED_TESTS=`grep -f ../stack_resources.out ../reports/cloudsploit_results.out | grep -c FAIL`
    MASKED_TESTS=0
  fi


  echo -e ""
  echo -e "Security Tests Passed: ${PASSED_TESTS}" > ../reports/security_scan_summary.out
  echo -e "Security Tests Failed: ${FAILED_TESTS}" >> ../reports/security_scan_summary.out
  echo -e "Security Tests Masked: ${MASKED_TESTS}" >> ../reports/security_scan_summary.out

  echo "" >> ../reports/security_scan_summary.out
  if [ $FAILED_TESTS -gt 0 ]; then
    local RESULT=1
  else
    local RESULT=0
  fi

  echo $RESULT
}

function main () {

  install_cloudsploit
  setup_cloudsploit
  run_cloudsploit

  RESULT=$(check_results)

  cat ../reports/security_scan_summary.out
  cat ../reports/cloudsploit_results.out | grep -f ../stack_resources.out
  echo ""
  if [ $RESULT -ne 0 ]; then
    exit 1
  else
    exit 0
  fi
}

# TODO - FUNCTION BELOW should be refactored to let the script assume a role to
#        Execute the scan as a security audit role (least permissions)
# function assume_role () {
#   #
#   # ./cloudsploit-wrapper.sh --profile=aws_profile_name
#   #
#
#   cd $CLOUDSPLOIT_DIR
#
#   WHOAMI=$(whoami)
#   BASENAME=$(basename "$0")
#   DIRNAME=$(dirname "$0")
#
#   PROFILE="$1"
#   ROLE2ASSUME="IamSecurityAuditRole"
#   SESSION="$WHOAMI-$BASENAME"
#
#   ACCOUNTID=$(aws $PROFILE sts get-caller-identity --query 'Account' --output text)
#   ROLEARN="arn:aws:iam::${ACCOUNTID}:role/${ROLE2ASSUME}"
#
#   eval $(aws $PROFILE sts assume-role --role-arn ${ROLEARN} \
#     --role-session-name "${SESSION}" \
#     --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
#     --output text | \
#     (read KEY SECRET TOKEN; echo "export AWS_ACCESS_KEY_ID=\"$KEY\"; \
#     export AWS_SECRET_ACCESS_KEY=\"$SECRET\"; export AWS_SESSION_TOKEN=\"$TOKEN\""))
#
#   ulimit -s 65500
#   node --stack-size=65500 "$DIRNAME/index.js"
#
# }

main
