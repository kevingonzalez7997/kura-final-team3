#####################################################################
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-1"
}
##################################### EC2 #############################################
resource "aws_instance" "jenkins_manager" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  vpc_security_group_ids =  [aws_security_group.manager.id]
  key_name = "D9"
  user_data = "${file("jenkins.sh")}"
  tags = {
    Name = "jenkins_manager"
  }

}

resource "aws_instance" "jenkins_agent" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.agent.id]
  key_name = "D9"
  user_data = "${file("agent.sh")}"
  root_block_device {
    volume_size = 12  # Set the desired volume size in GB
  }
  tags = {
    Name = "jenkins_agent"
  }
}

resource "aws_instance" "jenkins_agent2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.agent.id]
  key_name = "D9"
  user_data = "${file("agent.sh")}"
  root_block_device {
    volume_size = 12  # Set the desired volume size in GB
  }
  tags = {
    Name = "jenkins_agent2"
  }
}

resource "aws_instance" "jenkins_agent3" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.agent.id]
  key_name = "D9"
  user_data = "${file("agent.sh")}"
  root_block_device {
    volume_size = 12  # Set the desired volume size in GB
  }
  tags = {
    Name = "jenkins_agent3"
  }
}

###################SECURITY GROUP ##############################
resource "aws_security_group" "manager" {
    name = "manager"

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
    Name = "Manager"
  }

}
  
resource "aws_security_group" "agent" {
    name = "agent"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Agent"
  }
}
