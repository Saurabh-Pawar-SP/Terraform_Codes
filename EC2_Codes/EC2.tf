provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "EC2" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"
  key_name      = "EC2-Key-Terraform"
  
  vpc_security_group_ids = [
  "sg-0b49721a780e65e82"]

  monitoring           = true

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