# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.vpc_dns_hostnames
  enable_dns_support   = var.vpc_dns_support

  tags = {
    Owner = var.owner
    Name  = var.owner
  }
}

# Create a availability_zones
data "aws_availability_zones" "az" {

  all_availability_zones = true
  exclude_names = ["ua-east-2a", "ua-east-2b", "ua-east-2c"]

  filter {
    name   = "opt-in-status"
    values = ["not-opted-in", "opted-in"]
  }
}
# Create a subnet
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.sbn_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Owner = var.owner
    Name  = var.owner
  }
}



# Create security_group
resource "aws_security_group" "sg" {
  name        = "${var.owner}-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress = [{
    description      = "All traffic"
    protocol         = var.sg_ingress_proto
    from_port        = var.sg_ingress_ssh
    to_port          = var.sg_ingress_http
    cidr_blocks      = [var.sg_ingress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false

  }]

  egress = [{
    description      = "All traffic"
    protocol         = var.sg_egress_proto
    from_port        = var.sg_egress_all
    to_port          = var.sg_egress_all
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false

  }]

  tags = {
    Owner = var.owner
    Name  = var.owner

  }
}


# Create a network_interface
resource "aws_network_interface" "network_interface" {
  security_groups = [aws_security_group.sg.id]
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

# Create target_group

resource "aws_lb_target_group_attachment" "tg" {
  count            = var.count_instance
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(aws_instance.instance.*.id, count.index)
  port             = 80
}

resource "aws_lb_target_group" "tg" {
  name     = "lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    port     = 80
    protocol = "TCP"
  }
}


# Create (and display) an SSH key

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "local_file" "private_key" {
  content              = tls_private_key.example.private_key_pem
  file_permission      = "0600"
  directory_permission = "0777"
  filename             = "${var.path}/${var.key_name}.pem"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh

}


# Create instance
resource "aws_instance" "instance" {
  count                       = var.count_instance
  ami                         = lookup(var.ami, var.aws_region, var.owner)
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id

  key_name = aws_key_pair.generated_key.key_name

  #user_data = var.apache

  credit_specification {
    cpu_credits = "standard"
  }
  tags = {
    Name  = element(var.instance_tags, count.index)
    Batch = "5AM"
  }
}
# Create instance
resource "aws_instance" "master" {
  
  ami                         = lookup(var.ami, var.aws_region, var.owner)
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id

  key_name = aws_key_pair.generated_key.key_name

  #user_data = var.apache

  credit_specification {
    cpu_credits = "standard"
  }
  tags = {
    Name  = "master"
    
  }
}

# Create gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

# Create route_table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.rt_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Owner = var.owner
    Name  = var.owner
  }

}
# Create route_table_association
resource "aws_main_route_table_association" "table_association" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.rt.id
}

# Create loadbalancer
resource "aws_lb" "lb" {
  name                             = "lb-tf"
  enable_cross_zone_load_balancing = true
  internal                         = false
  load_balancer_type               = "network"
  subnet_mapping {
    subnet_id = aws_subnet.subnet.id
  }

  enable_deletion_protection = false

  tags = {
    Environment = "aws_lb"
  }
}


# Create listener
resource "aws_lb_listener" "lb" {

  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

#Config inventory Ansible
resource "local_file" "hosts" {
  content = templatefile("hosts.tpl",
    {
      dns  = aws_instance.instance.*.public_dns,
      path = var.path,
      pem  = var.key_name,
      web1 = aws_instance.instance[0].public_dns,
      web2 = aws_instance.instance[1].public_dns,
      web3 = aws_instance.master.public_dns,
      web_ip1 = aws_instance.instance[0].public_ip,
      web_ip2 = aws_instance.instance[1].public_ip

    }
  )
  filename = "/etc/ansible/hosts"
}
#run ansible script
resource "null_resource" "sp" {

  triggers = {
    host0          = aws_instance.instance[0].public_ip
    instance_state = "running"
    host1          = aws_instance.instance[1].public_ip
    instance_state = "running"
    arn            = aws_lb.lb.arn 
  }
  provisioner "local-exec" {
    command = "chmod +x script.sh"
  }

  provisioner "local-exec" {
    command = "./script.sh"
  }

}

/*
resource "aws_elb" "bar" {
  name               = "loadbalancer"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups    = var.security_groups
  # access_logs {
  #   bucket        = "foo"
  #   bucket_prefix = "bar"
  #   interval      = 60
  # }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }ssh -i "new.pem" ubuntu@ec2-3-129-204-17.us-east-2.compute.amazonaws.com

  # listener {
  #   instance_port      = 8000
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = aws_instance.foo.*.id
  cross_zone_load_balancing   = true
  idle_timeout                = 40
  connection_draining         = true
  connection_draining_timeout = 30

  tags = {
    Name = "loadbalancer"
  }
}
*/
