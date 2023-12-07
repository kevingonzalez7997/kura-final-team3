#!/bin/bash
########################### SUBNET ID ###############################################
# Retrieve subnet IDs from Terraform
# Output were created  in terraform file and now saved in variables

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
eksctl create cluster cluster01 --vpc-private-subnets=$subnet_id_private_a,$subnet_id_private_b --vpc-public-subnets=$subnet_id_public_a,$subnet_id_public_b

# apply deployment yaml which create app based on instructions 
#the service yaml takes care of ports and how traffic will get to the deployment
kubectl apply -f deployment.yaml && kubectl apply -f service.yaml
################################ ALB CONFIG ####################################################

#creates iam provider
eksctl utils associate-iam-oidc-provider --cluster cluster01 --approve

#create policy given the json file , 
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

### copy arn output.....subnets have been tagged on creation##

## figure out how to add arn here from previous command to fully automate 
eksctl create iamserviceaccount --cluster=cluster01 --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::288906493057:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve


############################# YAML FILES ###############################################
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds"

kubectl apply -f v2_4_5_full.yaml

kubectl apply -f ingressClass.yaml

kubectl apply -f ingress.yaml