pipeline {
    agent {label 'aws'}
    environment {
        AWS_PROD_CFT_S3_BUCKET     = credentials('jenkins-aws-prod-cft-s3-bucket')
        AWS_STAGE_CFT_S3_BUCKET    = credentials('jenkins-aws-stage-cft-s3-bucket')
        AWS_S3_ROOT_URL            = credentials('jenkins_aws_s3_root_url')
        //AWS_ACCESS_KEY_ID          = credentials('jenkins-aws-secret-key-id')
        //AWS_SECRET_ACCESS_KEY      = credentials('jenkins-aws-secret-access-key')
        CLOUDFORMATION             = 'landing-zone/BasicGoodLandingZone.yaml'
        CLOUDFORMATION_TEST_PARAMS ='./params/BasicGoodLandingZone_test_params.json'
    }

    stages {
      stage('Setup workspace') {
        steps {
            sh './util/_jenkins_setup_ws.sh'
        }
      }

        stage('Decompose Commit') {
          steps {
            sh './util/_jenkins_decompose_commit.sh'
          }
        }

        stage('Scan Code (Static)') {
          steps {
              sh './util/_jenkins_cfnlint_cft.sh'
          }
        }

        stage('Scan Code (Static Security)') {
          steps {
              sh './util/_jenkins_cfn_nag_scan.sh'
          }
        }

        stage('Build Test Env') {
          steps {
              sh './util/_jenkins_build_test_stack.sh'
          }
        }

        stage('Run Cloudsploit') {
          steps {
            sh './util/_jenkins_run_sec_scan.sh'
            }
        }

        stage('Delete Test Env') {
          steps {
            sh './util/_jenkins_delete_test_stack.sh'
          }
        }
        stage('Publish to Prod S3') {
          steps {
            sh './util/_jenkins_publish_to_prod_s3.sh'
          }
        }
    }

    post {
      always {
        junit "reports/*.xml"
        }
    }
}
