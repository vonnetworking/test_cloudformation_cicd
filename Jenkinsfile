pipeline {
    agent any

    stages {
        stage('Build') {
            if (isUnix()) {
                sh './gradlew'
            } else {
                bat 'gradlew.bat'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
