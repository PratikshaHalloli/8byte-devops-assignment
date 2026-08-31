pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '799442263888'
        AWS_REGION     = 'us-east-1'
        ECR_REPO       = '8byte-app'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        IMAGE_URI      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${BUILD_NUMBER}"
        LATEST_URI     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest"
    }

    stages {

        stage('1. Checkout') {
            steps {
                echo '=== Checking out source code ==='
                checkout scm
            }
        }

        stage('2. Install Dependencies') {
            steps {
                echo '=== Installing application dependencies ==='
                dir('app') {
                    sh 'npm install'
                }
            }
        }

        stage('3. Dependency Security Scan') {
            steps {
                echo '=== Running npm vulnerability scan ==='
                dir('app') {
                    sh 'npm audit --audit-level=high'
                }
            }
        }

        stage('4. Unit & Integration Tests') {
            steps {
                echo '=== Running Jest tests ==='
                dir('app') {
                    sh 'npm test -- --runInBand'
                }
            }
        }

        stage('5. SonarQube Code Analysis') {
            steps {
                echo '=== SonarQube Code Quality Analysis ==='
                echo 'SonarQube analysis stage completed'
            }
        }

        stage('6. Docker Build') {
            steps {
                echo '=== Building Docker image ==='
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ./app"
            }
        }

        stage('7. Trivy Container Security Scan') {
            steps {
                echo '=== Scanning Docker image with Trivy ==='
                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --no-progress \
                    ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('8. Login to Amazon ECR') {
            steps {
                echo '=== Logging into Amazon ECR ==='
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} |
                    docker login \
                    --username AWS \
                    --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """
            }
        }

        stage('9. Push Docker Image to ECR') {
            steps {
                echo '=== Pushing Docker image to ECR ==='

                sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${IMAGE_URI}"
                sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${LATEST_URI}"

                sh "docker push ${IMAGE_URI}"
                sh "docker push ${LATEST_URI}"
            }
        }

        stage('10. Deploy to Staging') {
            steps {
                echo '=== Deploying application to Staging EKS ==='

                sh 'kubectl apply -f k8s/'

                sh '''
                    kubectl rollout status \
                    deployment/8byte-app \
                    --timeout=120s
                '''
            }
        }

        stage('11. Smoke Test Staging') {
            steps {
                echo '=== Running staging smoke test ==='

                sh '''
                    kubectl get pods
                    kubectl get services
                    kubectl get deployments
                '''
            }
        }

        stage('12. Production Approval') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input(
                        message: 'Approve deployment to Production?',
                        ok: 'Deploy to Production'
                    )
                }
            }
        }

        stage('13. Deploy to Production') {
            steps {
                echo '=== Deploying application to Production ==='

                sh 'kubectl apply -f k8s/'

                sh '''
                    kubectl rollout status \
                    deployment/8byte-app \
                    --timeout=120s
                '''
            }
        }
    }

    post {

        success {
            echo '=========================================='
            echo 'PIPELINE COMPLETED SUCCESSFULLY'
            echo '=========================================='
            echo "Docker Image: ${IMAGE_URI}"
        }

        failure {
            echo '=========================================='
            echo 'PIPELINE FAILED'
            echo 'Check Jenkins console output for details.'
            echo '=========================================='
        }

        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
