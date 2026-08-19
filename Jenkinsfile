pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        ANSIBLE_HOST_KEY_CHECKING = "False"

        DOCKER_IMAGE = "ajiththomas10/html-app"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir('terraform') {

                        sh 'terraform init'

                        sh 'terraform validate'

                        sh 'terraform plan -out=tfplan'

                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Get Terraform Outputs') {
            steps {
                script {

                    env.MASTER_IP = sh(
                        script: 'cd terraform && terraform output -raw master_ip',
                        returnStdout: true
                    ).trim()

                    env.WORKER_IP = sh(
                        script: 'cd terraform && terraform output -raw worker_ip',
                        returnStdout: true
                    ).trim()

                    echo "Master IP: ${env.MASTER_IP}"
                    echo "Worker IP: ${env.WORKER_IP}"
                }
            }
        }

        stage('Generate Inventory') {
            steps {

                sh """
                cat > ansible/inventory.ini << EOF
[master]
${env.MASTER_IP}

[worker]
${env.WORKER_IP}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/k8s_key
EOF
                """
            }
        }

        stage('Add SSH Host Keys') {
            steps {

                sh """
                mkdir -p /var/lib/jenkins/.ssh

                ssh-keyscan -H ${env.MASTER_IP} >> /var/lib/jenkins/.ssh/known_hosts

                ssh-keyscan -H ${env.WORKER_IP} >> /var/lib/jenkins/.ssh/known_hosts
                """
            }
        }

        stage('Ansible Kubernetes Setup') {
            steps {

                dir('ansible') {

                    sh 'ansible-playbook -i inventory.ini site.yml'

                }
            }
        }

        stage('Verify Cluster') {
            steps {

                sh """
                ssh -o StrictHostKeyChecking=no \
                -i /var/lib/jenkins/.ssh/k8s_key \
                ubuntu@${env.MASTER_IP} \
                "kubectl get nodes"
                """
            }
        }

        stage('Build Docker Image') {
            steps {

                sh """
                docker build \
                -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \
                -t ${DOCKER_IMAGE}:latest \
                ./app
                """
            }
        }

        stage('Push Docker Image') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh """
                    echo "\${DOCKER_PASSWORD}" | docker login \
                    -u "\${DOCKER_USERNAME}" \
                    --password-stdin

                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    docker push ${DOCKER_IMAGE}:latest

                    docker logout
                    """
                }
            }
        }

        stage('Deploy Application') {
            steps {

                sh """
                scp -o StrictHostKeyChecking=no \
                -i /var/lib/jenkins/.ssh/k8s_key \
                kubernetes/deployment.yaml \
                kubernetes/service.yaml \
                ubuntu@${env.MASTER_IP}:/home/ubuntu/
                """

                sh """
                ssh -o StrictHostKeyChecking=no \
                -i /var/lib/jenkins/.ssh/k8s_key \
                ubuntu@${env.MASTER_IP} \
                "sed -i 's|YOUR_DOCKERHUB_USERNAME/html-app:latest|${DOCKER_IMAGE}:${BUILD_NUMBER}|g' deployment.yaml && \
                kubectl apply -f deployment.yaml && \
                kubectl apply -f service.yaml"
                """
            }
        }

        stage('Verify Application') {
            steps {

                sh """
                ssh -o StrictHostKeyChecking=no \
                -i /var/lib/jenkins/.ssh/k8s_key \
                ubuntu@${env.MASTER_IP} \
                "kubectl rollout status deployment/html-app && \
                kubectl get pods -o wide && \
                kubectl get service html-app-service"
                """
            }
        }
    }

    post {

        success {
            echo 'Kubernetes Cluster and HTML Application Deployed Successfully'
            echo "Application: http://${env.WORKER_IP}:30007"
        }

        failure {
            echo 'Pipeline Failed'
        }
    }
}
