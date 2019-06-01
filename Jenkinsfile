pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('jenkins-aws-secret-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
        CLOUDFORMATION = 'landing-zone/BasicGoodLandingZone.yaml'
        CLOUDFORMATION_TEST_PARAMS='./params/BasicGoodLandingZone_test_params.json'
    }

    stages {
        stage('Decompose Commit') {
          steps {
            sh './gradlew decompose'
          }
        }

        stage('Setup workspace') {
          steps {
              sh './gradlew setup'
          }
        }

        stage('Scan Code (Static)') {
          steps {
              sh './util/_jenkins_cfnlint_cft.sh'
          }
        }

        stage('Build Test Env') {
          environment {
            STACKNAME = sh(script: 'echo TestStack-$BUILD_NUMBER', returnStdout: true).trim()
          }
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
    }
    post {
      always {
        junit "./reports/sec_scan.xml"
        }
    }
}
