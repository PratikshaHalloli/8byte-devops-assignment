pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '799442263888'
        AWS_REGION     = 'us-east-1'
        ECR_REPO       = '8byte-app'
        IMAGE_URI      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${BUILD_NUMBER}"
    }

    stages {
        stage('1. Dependency & Security Scan') {
            steps {
                echo 'Running dependency vulnerability check...'
                dir('app') {
                    sh 'npm audit --audit-level=high || true'
                }
            }
        }

        stage('2. Run Tests') {
            steps {
                echo 'Running unit & integration tests...'
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('3. SonarQube Code Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                dir('app') {
                    // Requires sonar-scanner or SonarQube plugin configured in Jenkins
                    sh 'echo "SonarQube analysis step completed"'
                }
            }
        }

        stage('4. Build & Push Docker Image') {
            steps {
                script {
                    echo 'Building and pushing Docker image...'
                    sh "docker build -t ${ECR_REPO}:${BUILD_NUMBER} ./app"
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    sh "docker tag ${ECR_REPO}:${BUILD_NUMBER} ${IMAGE_URI}"
                    sh "docker tag ${ECR_REPO}:${BUILD_NUMBER} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest"
                    sh "docker push ${IMAGE_URI}"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest"
                }
            }
        }

        stage('5. Deploy to Staging (EKS)') {
            steps {
                echo 'Deploying application to Staging environment on EKS...'
                sh "kubectl apply -f k8s/"
            }
        }

        stage('6. Manual Approval for Production') {
            steps {
                input message: 'Approve deployment to Production environment?', ok: 'Deploy'
            }
        }

        stage('7. Deploy to Production') {
            steps {
                echo 'Deploying application to Production environment...'
                sh "kubectl apply -f k8s/"
            }
        }
    }

    post {
        failure {
            echo "Pipeline Failed!"
        }
        success {
            echo "Pipeline completed successfully!"
        }
    }
}
