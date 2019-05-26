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
                sh 'echo building stuff in AWS...'
                script {
                  STACKID = sh (
                             script: '/usr/local/bin/aws cloudformation create-stack  --stack-name TestStack-$BUILD_NUMBER --template-body file://./landing-zone/BasicGoodLandingZone.yaml --parameters file://./params/BasicGoodLandingZone_test_params.json | grep StackId | awk -F\':\' \'{print \$2}\' ',
                             returnStdout: true).trim()
                }
                sh 'echo $STACKID'
            }
        }
    }
}
