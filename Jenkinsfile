pipeline {
    agent any

    stages {
        stage('Decompose Commit') {
          steps {
            sh './gradlew decompose'
          }
        }
        stage('Scan Code') {
            steps {
                echo 'Running cfn-lint scans...'
                sh './gradlew cfnlint'
            }
        }
        stage('Build Test Env') {
            steps {
                echo 'Building test stack in AWS...'
                script {
                  STACKID = sh ( './util/_jenkins_create_test_stack.sh TestStack-$BUILD_NUMBER ../landing-zone/BasicGoodLandingZone.yaml ../params/BasicGoodLandingZone_test_params.json' )
                }
                echo 'Test stack created ARN = $STACKID'
            }
        }
        stage('Delete Test Env') {
          steps {
            echo 'Deleting test stack in AWS...'
            script {
              sh ('aws cloudformation delete-stack --stack-name=$STACKID')
            }
            echo 'Stack marked for deletion: $STACKID'
          }
        }
    }
}
