provider "aws" {
  region = "us-west-1"
}

data "aws_key_pair" "existing_k3s_key_pair" {
  key_name = "k3s-cluster-key"
}

resource "aws_instance" "orders_service_ec2" {
  ami           = "ami-0ce2cb35386fc22e9"
  instance_type = "t2.small"
  key_name      = data.aws_key_pair.existing_k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.naders_taters_sg.id]

  user_data = <<-EOF
              sudo apt update -y && sudo apt upgrade -y
              curl -sfL https://get.k3s.io | sh - 
              sudo apt install awscli -y
              aws s3 cp s3://naders-taters/orders-service/deployment.yml .
              export PUBLIC_IP=$(curl ipinfo.io/ip)
              echo "  - $PUBLIC_IP" >> deployment.yml
              EOF

  tags = {
    Name = "orders_service"
  }
}

resource "aws_instance" "products_service_ec2" {
  ami           = "ami-0ce2cb35386fc22e9"
  instance_type = "t2.small"
  key_name      = data.aws_key_pair.existing_k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.naders_taters_sg.id]

  user_data = <<-EOF
              sudo apt update -y && sudo apt upgrade -y
              curl -sfL https://get.k3s.io | sh - 
              sudo apt install awscli -y
              aws s3 cp s3://naders-taters/orders-service/deployment.yml .
              export PUBLIC_IP=$(curl ipinfo.io/ip)
              echo "  - $PUBLIC_IP" >> deployment.yml
              EOF

  tags = {
    Name = "products_service"
  }
}

resource "aws_security_group" "naders_taters_sg" {
  name        = "naders_taters_sg"
  description = "22-8000"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "orders_service_route53" {
  zone_id = "Z03133372F2CEQDM6FJ3C"
  name    = "orders.eddieeby.net"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.orders_service_ec2.public_ip]
}

resource "aws_route53_record" "products_service_route53" {
  zone_id = "Z03133372F2CEQDM6FJ3C"
  name    = "products.eddieeby.net"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.products_service_ec2.public_ip]
}
