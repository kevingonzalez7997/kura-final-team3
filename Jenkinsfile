pipeline {
    agent { label 'Agent' } 
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
                    dir('initTerra') {
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
                    dir('initTerra') {
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
                    dir('initTerra') {
                        sh 'terraform apply plan.tfplan'
                    }
                }
            }
        }

        stage('BuildImage') {
            steps {
              dir('Foodimg2Ing') {
                sh 'docker build --no-cache -t kevingonzalez7997/finalapp .'
              }
            }
        }

        stage('DockerHubLogin') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | sudo docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
        
        stage('Push') {
            steps {
              dir('Foodimg2Ing') {
                sh 'sudo docker push kevingonzalez7997/finalapp'
                sh 'docker rmi kevingonzalez7997/finalapp:latest'
              }
            }
        }
        
      stage('Deployeks') {
            steps {
                dir('initTerra') {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'), 
                        string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        
                        // Retrieve subnet IDs from Terraform
                        sh 'subnet_id_public_a=$(terraform output -raw subnet_id_public_a)'
                        sh 'subnet_id_public_b=$(terraform output -raw subnet_id_public_b)'
                        sh 'subnet_id_private_a=$(terraform output -raw subnet_id_private_a)'
                        sh 'subnet_id_private_b=$(terraform output -raw subnet_id_private_b)'

                        sh 'cd ../Kuber'

                        // Set up AWS CLI with credentials and configure the region
                        sh "aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}"
                        sh "aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}"
                        sh "aws configure set region us-east-1"

                        // Create EKS cluster using kubectl eksctl
                        sh 'eksctl create cluster cluster01 --vpc-private-subnets=$subnet_id_private_a,$subnet_id_private_b --vpc-public-subnets=$subnet_id_public_a,$subnet_id_public_b'

                        sh 'kubectl apply -f deployment.yaml && kubectl apply -f service.yaml'

                        sh 'eksctl utils associate-iam-oidc-provider --cluster cluster01 --approve'
                        sh 'aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json'

                        sh 'kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml ; kubectl apply -f v2_4_5_full.yaml ; kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds" ; kubectl apply -f ingressClass.yaml ; kubectl apply -f ingress.yaml'
                    }
                }
            }
        }
    }
}