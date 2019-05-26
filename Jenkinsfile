pipeline {
    agent any

    stages {
        stage('Decompose Commit') {
        #decomposes the commit looking for one or more changed cloudformations
        #or associated bootstraps; or handling updated lambdas
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
            }
        }
    }
}
