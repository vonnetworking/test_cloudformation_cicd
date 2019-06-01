pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('jenkins-aws-secret-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
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
              sh './gradlew cfnlint'
          }
        }

        stage('Build Test Env') {
          steps {
              sh './gradlew build_test_stack'
          }
        }

        stage('Run Cloudsploit') {
          steps {
            sh './gradlew run_sec_scan'
            post {
              always {
                junit "./reports/sec_scan.xml"
                }
              }
            }
        }

        stage('Delete Test Env') {
          steps {
            sh './gradlew delete_test_stack'
          }
        }
    }
}
