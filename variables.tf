# variables.tf

variable "keyName" {
   default = "<Place here the ssh key name in ASW EC2>"
}

variable "region" {
   default = "eu-central-1"
}

variable "instanceType" {
   default = "t2.micro"
}

# Ubuntu 22.04
variable "ami" {
   default = "ami-0caef02b518350c8b"
}

variable "securityGroupDefault" {
   default = "devops-cert_task-default-sg"
}

variable "securityGroupWeb" {
   default = "devops-cert_task-web-sg"
}

#####################
# builder vars
variable "instanceNameBuilder" {
   default = "devops-cert_task-builder"
}

#####################
# webserver vars
variable "instanceNameWebserver" {
   default = "devops-cert_task-webserver"
}

# end of variables.tf
