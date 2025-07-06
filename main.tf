#creating a vpc to eks cluster 

resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
 
  tags = {
    Name = "eks-vpc"
  }
}

#provisioning subnets in 2 azs for high availablity

resource "aws_subnet" "eks_subnets" {
  for_each = {
    a = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-west-2a"
    }
    b = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-west-2b"
    }
  }

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "eks-subnet-${each.key}"
  }
}
#igw-rt 
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_route_table_association" "rt_assoc_a" {
  subnet_id      = aws_subnet.eks_subnets["a"].id
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_route_table_association" "rt_assoc_b" {
  subnet_id      = aws_subnet.eks_subnets["b"].id
  route_table_id = aws_route_table.eks_public_rt.id
}

