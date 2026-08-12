provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "EC2" {

  # ============================================================
  # 1. BASIC INSTANCE CONFIGURATION
  # ============================================================

  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"

  availability_zone = "us-east-1a"

  tenancy = "default"

  # ============================================================
  # 2. NETWORKING
  # ============================================================

  subnet_id = "subnet-0123456789abcdef0"

  associate_public_ip_address = true

  private_ip = "10.0.1.50"

  vpc_security_group_ids = [
    "sg-0123456789abcdef0"
  ]

  # ============================================================
  # 3. SSH KEY
  # ============================================================

  key_name = "my-ec2-key"

  # ============================================================
  # 4. IAM INSTANCE PROFILE
  # ============================================================

  iam_instance_profile = "EC2-S3-Access-Role"

  # ============================================================
  # 5. MONITORING
  # ============================================================

  monitoring = true

  # ============================================================
  # 6. CPU OPTIONS
  # ============================================================

  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }

  # ============================================================
  # 7. CPU CREDIT CONFIGURATION
  # ============================================================

  credit_specification {
    cpu_credits = "standard"
  }

  # ============================================================
  # 8. ROOT EBS VOLUME
  # ============================================================

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    # kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx"
  }

  # ============================================================
  # 9. ADDITIONAL EBS VOLUME
  # ============================================================

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 50
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    # kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx"
  }

  # ============================================================
  # 10. EPHEMERAL INSTANCE STORE
  # ============================================================

  # Example only.
  # Not every EC2 instance type has instance-store disks.

  # ephemeral_block_device {
  #   device_name  = "/dev/sdb"
  #   virtual_name = "ephemeral0"
  # }

  # ============================================================
  # 11. USER DATA
  # ============================================================

  user_data = <<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo "Hello from Terraform EC2" > /var/www/html/index.html
  EOF

  user_data_replace_on_change = true

  # ============================================================
  # 12. USER DATA BASE64
  # ============================================================

  # user_data_base64 = "BASE64_ENCODED_SCRIPT"

  # ============================================================
  # 13. SHUTDOWN BEHAVIOR
  # ============================================================

  instance_initiated_shutdown_behavior = "stop"

  # ============================================================
  # 14. SOURCE / DESTINATION CHECK
  # ============================================================

  source_dest_check = true

  # ============================================================
  # 15. ENCLAVE
  # ============================================================

  enclave_options {
    enabled = false
  }

  # ============================================================
  # 16. HIBERNATION
  # ============================================================

  hibernation = false

  # ============================================================
  # 17. PRIVATE DNS NAME OPTIONS
  # ============================================================

  # Example:
  #
  # private_dns_name_options {
  #   hostname_type = "ip-name"
  #   enable_resource_name_dns_a_record = true
  #   enable_resource_name_dns_aaaa_record = false
  # }

  # ============================================================
  # 18. PLACEMENT GROUP
  # ============================================================

  # placement_group = "my-placement-group"

  # ============================================================
  # 19. HOST / DEDICATED HOST
  # ============================================================

  # host_id = "h-0123456789abcdef0"

  # host_resource_group_arn = "arn:aws:resource-groups:..."

  # ============================================================
  # 20. CPU / INSTANCE OPTIONS
  # ============================================================

  # disable_api_stop = false

  # disable_api_termination = false

  # ============================================================
  # 21. NETWORK INTERFACE
  # ============================================================

  # network_interface {
  #   device_index         = 1
  #   network_interface_id = "eni-0123456789abcdef0"
  # }

  # ============================================================
  # 22. IPV6
  # ============================================================

  # ipv6_address_count = 1

  # ipv6_addresses = [
  #   "2001:db8:1234:5678::10"
  # ]

  # ============================================================
  # 23. SECONDARY PRIVATE IP
  # ============================================================

  # private_ip = "10.0.1.50"

  # ============================================================
  # 24. INSTANCE METADATA OPTIONS
  # ============================================================

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # ============================================================
  # 25. CREDIT SPECIFICATION
  # ============================================================

  # Already configured above:
  #
  # credit_specification {
  #   cpu_credits = "standard"
  # }

  # ============================================================
  # 26. TAGS
  # ============================================================

  tags = {
    Name        = "myec2-server"
    Environment = "dev"
    Owner       = "Saurabh"
    Project     = "Terraform"
    Department  = "IT"
    ManagedBy   = "Terraform"
  }

  # ============================================================
  # 27. VOLUME TAGS
  # ============================================================

  volume_tags = {
    Name        = "myec2-volume"
    Environment = "dev"
    Owner       = "Saurabh"
    ManagedBy   = "Terraform"
  }

  # ============================================================
  # 28. LIFECYCLE
  # ============================================================

  lifecycle {
    create_before_destroy = false

    # prevent_destroy = true

    # ignore_changes = [
    #   tags,
    # ]
  }
}