provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"
  key_name      = "EC2-Key-Terraform"

  vpc_security_group_ids = [
    "sg-0730d84ed500ae558"
  ]

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "myec2-server"
    Environment = "dev"
    Owner       = "Saurabh"
    Project     = "Terraform"
    Department  = "IT"
  }
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ec2.id
}

output "ec2_instance_name" {
  description = "EC2 instance Name"
  value       = aws_instance.ec2.tags["Name"]
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.ec2.public_ip
}

output "ebs_volume_id" {
  description = "Additional EBS volume ID"
  value = [
    for ebs in aws_instance.ec2.ebs_block_device : ebs.volume_id
  ]
}

output "ebs_device_name" {
  description = "Additional EBS device name"
  value = [
    for ebs in aws_instance.ec2.ebs_block_device : ebs.device_name
  ]
}

output "ebs_volume_size" {
  description = "Additional EBS volume size in GB"
  value = [
    for ebs in aws_instance.ec2.ebs_block_device : ebs.volume_size
  ]
}