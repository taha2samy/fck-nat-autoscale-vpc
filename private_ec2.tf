resource "aws_iam_role" "nat_role" {
  name = "fck-nat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "nat_policy" {
  name = "fck-nat-policy"
  role = aws_iam_role.nat_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:ReplaceRoute",
          "ec2:DescribeRouteTables",
          "ec2:CreateRoute"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nat_profile" {
  name = "fck-nat-profile"
  role = aws_iam_role.nat_role.name
}

data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "fck_nat_lt" {
  name_prefix   = "fck-nat-lt-"
  image_id      = data.aws_ami.fck_nat.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.nat_instance.key_name




  iam_instance_profile {
    name = aws_iam_instance_profile.nat_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.fck_nat_sg.id]
    delete_on_termination       = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region         = var.region
    route_table_id = aws_route_table.private.id
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "fck-nat-asg"
    }
  }
}

resource "aws_autoscaling_group" "fck_nat_asg" {
  name                = "fck-nat-asg"
  vpc_zone_identifier = [aws_subnet.public.id]


  desired_capacity = 1
  min_size         = 1
  max_size         = 1

  launch_template {
    id      = aws_launch_template.fck_nat_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "fck-nat-instance"
    propagate_at_launch = true
  }
}


resource "tls_private_key" "nat_instance" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "local_file" "put_key_on_local_file" {
  content         = tls_private_key.nat_instance.private_key_pem
  filename        = "${path.module}/private_key.pem"
  file_permission = "0400"
}
resource "aws_key_pair" "nat_instance" {
  key_name   = "fck-nat-key"
  public_key = tls_private_key.nat_instance.public_key_openssh
}
