provider "aws" {
  region = "us-west-1"
}

data "aws_key_pair" "existing_k3s_key_pair" {
  key_name = "k3s-cluster-key"
}

resource "aws_iam_role" "s3_full_access_role" {
  name = "s3_full_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.s3_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "s3_full_access_instance_profile" {
  name = "s3_full_access_instance_profile"
  role = aws_iam_role.s3_full_access_role.name
}

resource "aws_instance" "orders_service_ec2" {
  ami           = "ami-0ce2cb35386fc22e9"
  instance_type = "t2.small"
  key_name      = data.aws_key_pair.existing_k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.naders_taters_sg.id]
  iam_instance_profile = aws_iam_instance_profile.s3_full_access_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo snap install aws-cli --classic
              curl -sfL https://get.k3s.io | sh - 
              aws s3 cp s3://naders-taters/orders-service/deployment.yml .
              export PUBLIC_IP=$(curl ipinfo.io/ip)
              echo "  - $PUBLIC_IP" >> deployment.yml
              sudo kubectl apply -f deployment.yml
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
  iam_instance_profile = aws_iam_instance_profile.s3_full_access_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo snap install aws-cli --classic
              curl -sfL https://get.k3s.io | sh - 
              aws s3 cp s3://naders-taters/products-service/deployment.yml .
              export PUBLIC_IP=$(curl ipinfo.io/ip)
              echo "  - $PUBLIC_IP" >> deployment.yml
              sudo kubectl apply -f deployment.yml
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
