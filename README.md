# 🚀 Terraform AWS Infrastructure

> Production-ready AWS infrastructure automated using **Terraform Infrastructure as Code (IaC)**.

![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)
![DevOps](https://img.shields.io/badge/DevOps-Automation-blue)

## 📌 Overview

This repository contains the sample Terraform configurations to provision and manage AWS infrastructure securely, consistently, and efficiently.

### ☁️ AWS Services

* 🪣 S3
* 🌐 VPC
* 🖥️ EC2
* ⚖️ ALB
* 📈 Auto Scaling
* 🗄️ RDS
* 🔐 IAM
* 📊 CloudWatch
* 🔑 KMS

## 🏗️ Architecture

```text
Developer
   │
   ▼
 GitHub
   │
   ▼
Terraform
   │
   ▼
┌──────────────────────────┐
│         AWS Cloud        │
│                          │
│ VPC → ALB → EC2 → RDS   │
│              │           │
│              └── S3      │
│                          │
│ IAM + KMS + CloudWatch   │
└──────────────────────────┘
```

## 🚀 Terraform Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

## 🔐 Key Features

* Infrastructure as Code
* Reusable Terraform modules
* Dev / Stage / Prod environments
* S3 encryption & versioning
* IAM least privilege
* Secure VPC architecture
* Remote Terraform state
* CloudWatch monitoring
* Lifecycle & cost optimization
* CI/CD ready

## ⚠️ Security

Never commit:

```text
*.tfstate
*.tfvars
.env
AWS access keys
secret keys
```

## 👨‍💻 Author

**Saurabh Pawar**
Cloud & DevOps Engineer

**Skills:** AWS • Terraform • Docker • Kubernetes • Jenkins • Linux • CI/CD

⭐ If you find this project useful, consider starring the repository.
