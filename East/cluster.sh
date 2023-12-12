#!/bin/bash
########################### SUBNET ID ###############################################
# Retrieve subnet IDs from Terraform
# Output were created in terraform file and now saved in variables

subnet_id_public_a=$(terraform output -raw subnet_id_public_a)
subnet_id_public_b=$(terraform output -raw subnet_id_public_b)
subnet_id_private_a=$(terraform output -raw subnet_id_private_a)
subnet_id_private_b=$(terraform output -raw subnet_id_private_b)
# Outputs are local to the initTerra dir

# Kuber dir has all necessary files
cd ../Kuber
########################## AWS CLI CONFIG ##########################################
# Using the creditians created in jenkins and passing them to aws cli configure 
# must have this setup to have access to aws account 
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws configure set region us-east-1
######################### CLUSTER CREATION ###########################################
#creating a cluster given the subnets id that have been stored in variables
eksctl create cluster cluster01 --vpc-private-subnets=$subnet_id_private_a,$subnet_id_private_b --vpc-public-subnets=$subnet_id_public_a,$subnet_id_public_b --without-nodegroup
#create cluster of size t2.med
eksctl create nodegroup --cluster cluster01 --node-type t2.medium --nodes 2 
# apply deployment yaml which create app based on instructions 
#the service yaml takes care of ports and how traffic will get to the deployment
kubectl apply -f deployment.yaml 
kubectl apply -f service.yaml

sleep 240s
################################ ALB CONFIG ####################################################
#creates iam provider so that eks can connect to IAM
eksctl utils associate-iam-oidc-provider --cluster cluster01 --approve

#create policy given the json file 
# capture the output 

output=(aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json)

# Extract the ARN from the output using grep 
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

#########################################CLOUD WATCH AGENT###############################################
#To use Container Insights with enhanced observability for Amazon EKS, 
#you must use the Amazon CloudWatch Observability EKS add-on or the CloudWatch agent. 

#First, set up the necessary permissions by attaching the CloudWatchAgentServerPolicy and AWSXrayWriteOnlyAccess IAM policies to your worker nodes. 
#role name will be in eks console copy without the arn
aws iam attach-role-policy \
  --role-name eksctl-cluster01-cluster-ServiceRole-GSRAVF7Kjmqs \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess


#Enter the following command to install the add-on:
#ensure cluster name 
eksctl create-addon --cluster-name cluster01 --addon-name amazon-cloudwatch-observability
