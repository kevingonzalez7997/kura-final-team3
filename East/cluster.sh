#!/bin/bash
########################## AWS CLI CONFIG ##########################################
# Using the credentials created in Jenkins and passing them to aws cli configure 
# must have this setup to have access to AWS account 
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws configure set region us-east-1

########################### SUBNET ID ###############################################
# Retrieve subnet IDs from Terraform
# Output was created in terraform file and now saved in variables

subnet_id_public_a=$(terraform output -raw subnet_id_public_a)
subnet_id_public_b=$(terraform output -raw subnet_id_public_b)
subnet_id_private_a=$(terraform output -raw subnet_id_private_a)
subnet_id_private_b=$(terraform output -raw subnet_id_private_b)
# Outputs are local to the initTerra dir

vpc_id=$(terraform output -raw d10_vpc_id)
vpc_cidr=$(terraform output -raw vpc_cidr)
vpc_route=$(terraform output -raw private_route_id)

echo "East vpc id: $vpc_id" > vpc.txt
echo "East vpc cidr: $vpc_cidr" >> vpc.txt
echo "East vpc route: $vpc_route" >> vpc.txt

aws s3 cp vpc.txt s3://d10bucket/

# Kuber dir has all the necessary files
cd ../kuber/
######################### CLUSTER CREATION ###########################################
#creating a cluster given the subnets id that have been stored in variables
eksctl create cluster cluster01 --vpc-private-subnets=$subnet_id_private_a,$subnet_id_private_b --vpc-public-subnets=$subnet_id_public_a,$subnet_id_public_b --without-nodegroup
#create cluster of size t2.med
eksctl create nodegroup --cluster cluster01 --node-type p2.xlarge --nodes 2 
# apply deployment yaml which create app based on instructions 
#the service yaml takes care of ports and how traffic will get to the deployment
kubectl apply -f recipe-generator-deployment.yaml
kubectl apply -f recipe-generator-service.yaml
sleep 240s
################################ ALB CONFIG ####################################################
#creates iam provider so that eks can connect to IAM
eksctl utils associate-iam-oidc-provider --cluster cluster01 --approve

#create policy given the json file 
# capture the output 
output=$(aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json)

# Extract the ARN from the output using grep or other string manipulation
arn=$(echo "$output" | jq -r '.Policy.Arn')

## Use varaibale to create iam service
eksctl create iamserviceaccount --cluster=cluster01 --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn="$arn" --override-existing-serviceaccounts --approve
############################# YAML FILES ###############################################
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
sleep 45s
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds"
sleep 45s
kubectl apply -f v2_4_7_full.yaml
sleep 45s
kubectl apply -f ingressClass.yaml  
sleep 45s
kubectl apply -f ingress.yaml
sleep 45s
kubectl apply -f nginx-proxy-service.yaml
sleep 20s
kubectl apply -f redis-leader-service.yaml 
sleep 20s
kubectl apply -f nginx-config.yaml
sleep 20s
kubectl apply -f nginx-deployment.yaml
sleep 20s
kubectl apply -f redis-leader-statefulset.yaml
sleep 20s
kubectl apply -f celery-deployment.yaml

kubectl apply -f recipe-generator-hpa.yaml

eksctl create iamidentitymapping  --region us-east-1 --cluster cluster01  --arn arn:aws:iam::294733426135:role/eks-lambda-role --username admin --group system:masters

