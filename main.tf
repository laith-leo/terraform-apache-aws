provider "aws" {
  region  = "us-east-2"
  access_key = "AKIAXXXXXXXXXXX" #REPLACE IT WITH YOURS, HOWEVER IT IS NOT RECOMMENDED TO HAVE THE KEY HERE. YOU HAVE BEEN WARNNED!!!!
  secret_key = "1XXXXXXXXXXXXXXXXXXXXX" #REPLACE IT WITH YOURS, HOWEVER IT IS NOT RECOMMENDED TO HAVE THE KEY HERE.YOU HAVE BEEN WARNNED!!!!
}

resource "aws_vpc" "terraform" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "Apache"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "Prod"
  }
}

resource "aws_subnet" "subnet-1" {

  vpc_id  = aws_vpc.terraform.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.r.id
}


resource "aws_security_group" "open" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.terraform.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_everything"
  }
}


resource "aws_network_interface" "webserver-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.open.id]

}

resource "aws_eip" "eip" {
  instance = aws_instance.ec2_terraform.id
  network_interface = aws_network_interface.webserver-nic.id
  associate_with_private_ip = "10.0.1.50"
  vpc      = true
}

resource "aws_instance" "ec2_terraform" {
 ami = "ami-08962a4068733a2b6"
 instance_type = "t2.micro"
 availability_zone = "us-east-2a"
 key_name = "terraform"
 network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.webserver-nic.id
 }

 user_data = <<-EOF
             #!/bin/bash
             sudo apt update -y
             sudo apt install apache2 -y
             sudo systemctl start apache2
             sudo echo "Hello Terraform!!!!" > /var/www/html/index.html
             EOF
}
