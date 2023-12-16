pipeline {
    agent { label 'agent' } 
    environment {
        DOCKERHUB_CREDENTIALS = credentials('kevingonzalez7997-dockerhub')
    }
    
    stages {
        stage('Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')
                ]) {
                    dir('East') {
                        sh 'terraform init' 
                    }
                }
            }
        }
        
        stage('Plan') {
            
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')
                ]) {
                    dir('East') {
                    sh 'terraform plan -out plan.tfplan -var="aws_access_key=$aws_access_key" -var="aws_secret_key=$aws_secret_key"'                    }
                }
            }
        }
        
        stage('Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')
                ]) {
                    dir('East') {
                        sh 'terraform apply plan.tfplan'
                    }
                }
            }
        }
      stage('Deploy EKS') {
            steps {
                dir('East') {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'), 
                        string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        
                        // Retrieve subnet IDs from Terraform
                        sh 'chmod +x ./cluster.sh'
                        sh './cluster.sh'
                    }
                }
            }
        }
    }
}
