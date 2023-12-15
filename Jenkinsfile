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


        // stage('BuildImage') {
        //     steps {
        //       dir('.') {
        //         sh 'docker build --no-cache -t kevingonzalez7997/finalapp .'
        //       }
        //     }
        // }

        // stage('DockerHubLogin') {
        //     steps {
        //         sh 'echo $DOCKERHUB_CREDENTIALS_PSW | sudo docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
        //     }
        // }
        
        // stage('Push') {
        //     steps {
        //       dir('.') {
        //         sh 'sudo docker push kevingonzalez7997/finalapp'
        //         sh 'docker rmi kevingonzalez7997/finalapp:latest'
        //       }
        //     }
        // }
        
        stage('Deploy EKS') {
            steps {
              dir('Kuber') {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')
                ]) {
                    sh './clusterw.sh'
                }
              }
            }
        }

    }
}
