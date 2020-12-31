#Creating SG for LB, only port TCP/80, TCP/443 and outbound access#

resource "aws_security_group" "lb_sg" {
  provider    = aws.region-master
  name        = "lb_sg"
  description = "Allow port 443 and traffic access to jenkins SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow port 443 to anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow port 80 to anywhere for redirection"
    from_port   = 80
    to_port     = 80
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


#Creating SG allowing port TCP/8080 from anywhere and TCP/22 from your IP in useast-1 #

resource "aws_security_group" "jenkins-sg" {
  provider    = aws.region-master
  name        = "jenkins-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "allow anyone on port 8080"
    from_port       = var.webserver-port
    to_port         = var.webserver-port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "allow traffic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating SG for allowing port 22 to your ip from us-east-2#

resource "aws_security_group" "jenkins-sg-useast2" {
  provider    = aws.region-worker
  name        = "jenkins-sg-useast2"
  description = "Allow port TCP/22 and port TCP/8080"
  vpc_id      = aws_vpc.vpc_worker_ohio.id
  ingress {
    description = "Allow port 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }

  ingress {
    description = "Allow traffic from us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


