
# ---------------------------------------------------------
# 1. Get Latest Ubuntu AMI (x86_64)
# ---------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Official Ubuntu Owner)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------------------------------------------------------
# 2. Security Group for Private Instance
# ---------------------------------------------------------
resource "aws_security_group" "private_sg" {
  name        = "private-ubuntu-sg"
  description = "Allow internal traffic only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

# ---------------------------------------------------------
# 3. Create the Private EC2 Instance
# ---------------------------------------------------------
resource "aws_instance" "private_app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  # Placing it in the Private Subnet
  subnet_id = aws_subnet.private.id

  # Attaching the Security Group
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  # Using the key created earlier
  key_name = aws_key_pair.nat_instance.key_name

  # No Public IP needed for private subnet
  associate_public_ip_address = false

  tags = {
    Name = "private-ubuntu-app"
  }
}

output "private_instance_ip" {
  value       = aws_instance.private_app.private_ip
  description = "The Private IP of the Ubuntu instance"
}
