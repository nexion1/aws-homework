terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "eu-north-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


resource "aws_instance" "builder" {
  ami                    = "ami-00466bdeb1cc0a297"
  instance_type          = "t3.micro"
  key_name               = "yandex_ag4544"
  vpc_security_group_ids = ["sg-0a8b283e9d3e532f9"]
  tags = {
    Purpose = "Builder machine"
  }
}

resource "aws_instance" "webserver" {
  ami                    = "ami-00466bdeb1cc0a297"
  instance_type          = "t3.micro"
  key_name               = "yandex_ag4544"
  vpc_security_group_ids = ["sg-0a8b283e9d3e532f9"]
  tags = {
    Purpose = "Webserver production"
  }
}

resource "aws_eip" "builder" {
  instance = aws_instance.builder.id
  vpc      = true
}

resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id
  vpc      = true
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/hostinventory.tpl", {
    server_public_ip_builder = aws_eip.builder.public_ip,
  server_public_ip_webserver = aws_eip.webserver.public_ip })
  filename = "${path.module}/ansible/hosts.yml"
}

output "summary" {
  value = [aws_eip.builder.public_ip, aws_eip.webserver.public_ip]
}

resource "null_resource" "ansible_playbook" {
  provisioner "local-exec" {
    command = "sleep 60 && ansible-playbook -i ./ansible/hosts.yml ./ansible/main.yml"
  }
  depends_on = [local_file.ansible_inventory]
}