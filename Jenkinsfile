pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
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
                        sh 'aws sts get-caller-identity'
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform plan -out=tfplan'
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Generate Inventory') {
            steps {
                script {

                    def MASTER_IP = sh(
                        script: 'cd terraform && terraform output -raw master_ip',
                        returnStdout: true
                    ).trim()

                    def WORKER_IP = sh(
                        script: 'cd terraform && terraform output -raw worker_ip',
                        returnStdout: true
                    ).trim()

                    writeFile file: 'ansible/inventory.ini', text: """
[master]
${MASTER_IP}

[worker]
${WORKER_IP}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/k8s_key
"""
                }
            }
        }

        stage('Ansible') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini site.yml'
                }
            }
        }

    }
}
