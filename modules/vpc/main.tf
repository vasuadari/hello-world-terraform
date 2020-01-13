variable "cidr_block" {
  type = string
}

variable "subnet" {
  type = map
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = "main"
  }
}

# Create a Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  availability_zone = var.subnet.public.availability_zone
  cidr_block = var.subnet.public.cidr_block

  tags = {
    Name = "public subnet"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a elastic ip for a NAT gateway
resource "aws_eip" "ngw" {
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "ngw eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }
}

# Create a private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "private rt"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  availability_zone = var.subnet.private.availability_zone
  cidr_block = var.subnet.private.cidr_block

  tags = {
    Name = "private subnet"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

