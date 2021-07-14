# Variable ami map
variable "ami" {
  type = map(any)
  default = {
    "us-east-2" = "ami-00399ec92321828f5"

  }
}


# Script_site
variable "apache" {
  default = <<-EOF
    #!/bin/bash
    sudo su
    apt-get update
    
    // apt-get install apache2 -y
    // sudo chmod 777 /var/www/html/
    // rm /var/www/html/index.html
    // echo '<!DOCTYPE html PUBLIC"-//W3C//DTD HTML 4.01 Transitional//EN">
    //       <html>
    //       <head>
    //       <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    //       <title>VM-1</title>
    //       </head>
    //       <body>
    //       <h1>Hello, I am</h1>
    //       <p>VM-1</p>
    //       </body>
    //       </html>' >> /var/www/html/index.html
    
    // sudo systemctl enable apache2
    // sudo systemctl start apache2
    
    EOF
}
#apt-get install mc -y

variable "ssh" {
  default = <<-EOF
    #!/bin/bash
   
    EOF
}


# Variables for VPC
variable "vpc_cidr_block" {
  description = "CIDR block VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_dns_support" {
  description = "DNS VPC"
  type        = bool
  default     = true
}

variable "vpc_dns_hostnames" {
  description = "DNS hostnames VPC"
  type        = bool
  default     = true
}

# Variables for Subnet
variable "sbn_public_ip" {
  description = "Public IP subnet"
  type        = bool
  default     = true
}

variable "sbn_cidr_block" {
  description = "CIDR subnet"
  type        = string
  default     = "172.16.10.0/24"
}

# Variables for Provider

variable "aws_region" {
  description = ""
  type        = string
  default     = "us-east-2"
}

variable "owner" {
  description = "#owner"
  type        = string
  default     = "224871185018"
}

variable "aws_region_az" {
  type    = string
  default = "us-east-2a"
}

variable "instance_tags" {
  description = "instance tags"
  type        = list(any)
  default     = ["vm-1", "vm-2"]
}

variable "instance_type" {
  description = "Type of the instance"
  type        = string
  default     = "t2.micro"
}


variable "count_instance" {
  description = "Counter"
  default     = "2"
}
# Variables for Security Group

variable "sg_ingress_proto" {
  description = "Protocol ingress"
  type        = string
  default     = "TCP"
}

variable "sg_ingress_ssh" {
  description = "Port ingress"
  type        = string
  default     = "22"
}
variable "sg_ingress_http" {
  description = "Port ingress"
  type        = string
  default     = "8080"
}

variable "sg_ingress_all" {
  description = "Port ingress"
  type        = string
  default     = "-1"
}

variable "sg_ingress_cidr_block" {
  description = "CIDR block ingress"
  type        = string
  default     = "0.0.0.0/0"
}

variable "sg_egress_proto" {
  description = "Protocol egress"
  type        = string
  default     = "-1"
}

variable "sg_egress_all" {
  description = "Port egress"
  type        = string
  default     = "0"
}

variable "sg_egress_cidr_block" {
  description = "CIDR block egress"
  type        = string
  default     = "0.0.0.0/0"
}


# Variables for Route Table
variable "rt_cidr_block" {
  description = "CIDR block route"
  type        = string
  default     = "0.0.0.0/0"
}

# Variables for Key
variable "key_name" {
  description = "key"
  type        = string
  default     = "new"
}


variable "path" {
  description = "key_path_ssh"
  default     = "/home/ars/Desktop/aws_jenkins_pipeline_training/~/.ssh/"

}

variable "ssh_keyname" {
  description = ""
  default     = "~/.ssh/new"
}

#Availability zones
variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    us-east-1      = 1
    us-west-1      = 2
    us-west-2      = 3
    eu-central-1   = 4
    ap-northeast-1 = 5
  }
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}