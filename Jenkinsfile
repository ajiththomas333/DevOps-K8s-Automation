pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        ANSIBLE_HOST_KEY_CHECKING = "False"
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

                    MASTER_IP = sh(
                        script: 'cd terraform && terraform output -raw master_ip',
                        returnStdout: true
                    ).trim()

                    WORKER_IP = sh(
                        script: 'cd terraform && terraform output -raw worker_ip',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Generate Inventory') {
            steps {

                sh """
                cat > ansible/inventory.ini << EOF
[master]
${MASTER_IP}

[worker]
${WORKER_IP}

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

                ssh-keyscan -H ${MASTER_IP} >> /var/lib/jenkins/.ssh/known_hosts

                ssh-keyscan -H ${WORKER_IP} >> /var/lib/jenkins/.ssh/known_hosts
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
                ubuntu@${MASTER_IP} \
                "kubectl get nodes"
                """

            }
        }

    }

    post {

        success {
            echo 'Kubernetes Cluster Created Successfully'
        }

        failure {
            echo 'Pipeline Failed'
        }

    }

}
