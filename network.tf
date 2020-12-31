#create VPC in us-east-1#

resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

#create VPC in us-east-2#

resource "aws_vpc" "vpc_worker_ohio" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}



#create IGW in us-east-1#

resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

#create IGW in us-east-2#

resource "aws_internet_gateway" "igw-ohio" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_ohio.id

}

#Get all AZ in VPC for master region#

data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

#create subnet #1 in us-east-1#

resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  cidr_block        = "10.0.0.0/24"
}


#create subnet #2 in us-east-1#

resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  cidr_block        = "10.0.2.0/24"
}


#create subnet in us-east-2#

resource "aws_subnet" "subnet_1_ohio" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker_ohio.id
  cidr_block = "192.168.1.0/24"

}

#initiate vpc peering connection request from region us-east-1#

resource "aws_vpc_peering_connection" "useast1-useast2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_worker_ohio.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
}

#Accept VPC peering connections in us-east-2 from us-east-1#

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-useast2.id
  auto_accept               = true
}

#create route table in us-east-1#

resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }

  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-useast2.id
  }

  lifecycle {
    ignore_changes = all

  }

  tags = {
    Name = "Master-Region-RT"
  }


}


#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}


#Create route table in us-east-2#

resource "aws_route_table" "internet-route-useast2" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_ohio.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-ohio.id
  }

  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-useast2.id

  }
  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "Worker-Region-RT"

  }


}

#Overwrite default route table of VPC (worker) with our route table entries #

resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker_ohio.id
  route_table_id = aws_route_table.internet-route-useast2.id
}

