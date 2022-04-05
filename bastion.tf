resource "aws_instance" "bastian" {
  ami                    = "ami-04a50faf2a2ec1901"
  instance_type          = "t2.micro"
  subnet_id   = var.public2_cidr

  tags = {
    Name = "bastian host"
  }
}

resource "aws_security_group" "web-sg" {
  name = "bastian-sg"
  ingress {
    from_port   = 22
    to_port     = 22
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
