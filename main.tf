# main.tf

######
# create ec2 default security group
resource "aws_security_group" "sg_default" {
  name = var.securityGroupDefault
  description = "[Terraform] Default ACL"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
######

######
# create ec2 web security group
resource "aws_security_group" "sg_web" {
  name = var.securityGroupWeb
  description = "[Terraform] Web ACL"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
######

# create ec2 builder instance
resource "aws_instance" "builder_instance" {
  ami                        = var.ami
  instance_type              = var.instanceType
  key_name                   = var.keyName
  vpc_security_group_ids     = [ aws_security_group.sg_default.id ]

  tags = {
    Name = var.instanceNameBuilder
  }

  volume_tags = {
    Name = var.instanceNameBuilder
  }
}

# create ec2 webserver instance
resource "aws_instance" "webserver_instance" {
  ami                        = var.ami
  instance_type              = var.instanceType
  key_name                   = var.keyName
  vpc_security_group_ids     = [ aws_security_group.sg_default.id,
                                 aws_security_group.sg_web.id ]

  tags = {
    Name = var.instanceNameWebserver
  }

  volume_tags = {
    Name = var.instanceNameWebserver
  }
}

# end of main.tf
