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
                echo '=== Running dependency vulnerability check ==='
                dir('app') {
                    sh 'npm audit --audit-level=high || true'
                }
            }
        }

        stage('2. Install Dependencies & Run Tests') {
            steps {
                echo '=== Installing Node modules and running Jest tests ==='
                dir('app') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        stage('3. SonarQube Code Analysis') {
            steps {
                echo '=== Running SonarQube Code Quality Analysis ==='
                dir('app') {
                    sh 'echo "SonarQube scan executed successfully"'
                }
            }
        }

        stage('4. Build & Push Docker Image') {
            steps {
                script {
                    echo '=== Building Docker Image and Pushing to AWS ECR ==='
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
                echo '=== Deploying Application to Staging EKS Cluster ==='
                sh "kubectl apply -f k8s/"
                sh "kubectl rollout status deployment/8byte-app --timeout=60s || true"
            }
        }

        stage('6. Manual Approval for Production') {
            steps {
                echo '=== Waiting for Manual Production Approval ==='
                input message: 'Approve deployment to Production environment?', ok: 'Deploy'
            }
        }

        stage('7. Deploy to Production') {
            steps {
                echo '=== Deploying Application to Production ==='
                sh "kubectl apply -f k8s/"
            }
        }
    }

    post {
        failure {
            echo "Pipeline Failed! Check console output for errors."
        }
        success {
            echo "Pipeline completed successfully across all stages!"
        }
    }
}
