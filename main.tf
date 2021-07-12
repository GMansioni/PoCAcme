// Proveedor
provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

//Reglas de acceso
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http_sg"
  description = "Allow inbound SSH and HTTP"
  vpc_id = aws_vpc.mi_vpc.id

//Se deberia restringir a IP's de confianza o internas segun el caso
  ingress {
    description = "inbound ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound prometheus"
    from_port   = 9090
    to_port     = 9253
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }

}

// VPC e Internet Gateway
resource "aws_vpc" "mi_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "Acme"
  }
}

resource "aws_subnet" "mi_subnet" {
   vpc_id = aws_vpc.mi_vpc.id
   cidr_block = "172.16.0.0/24"
   map_public_ip_on_launch = "true"

   tags = {
     Name  = "Acme Subnet"
   }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mi_vpc.id

  tags = {
    Environment = "ACME Testing"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.mi_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Environment = "ACME Testing"
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.mi_subnet.id
  route_table_id = aws_route_table.rtb_public.id
}

// Creacion de claves
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits = "4096"
}

// Recurso de clave
resource "aws_key_pair" "ec2_key_pair" {
  key_name = "ACME-Key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

//Creamos la clave privada
resource "local_file" "ec2_private_key_file" {
  content     = tls_private_key.ec2_key.private_key_pem
  filename = "./private_key.pem"

  provisioner "local-exec" {
    command = "chmod 400 ./private_key.pem"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.allow_ssh_http.id}" ]
  subnet_id = aws_subnet.mi_subnet.id
  key_name = aws_key_pair.ec2_key_pair.key_name
  private_ip = "172.16.0.10"
  associate_public_ip_address = true

  tags = {
      Name = "web_server"
    }

  depends_on = [
   aws_security_group.allow_ssh_http
  ]
}

resource "aws_instance" "grafana" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.allow_ssh_http.id}" ]
  subnet_id = aws_subnet.mi_subnet.id
  key_name = aws_key_pair.ec2_key_pair.key_name
  private_ip = "172.16.0.20"
  associate_public_ip_address = true

  tags = {
    Name = "grafana_server"
  }

  depends_on = [
   aws_security_group.allow_ssh_http
  ]
}

resource "time_sleep" "Esperamos_30s" {
  depends_on = [
     aws_instance.web,
     aws_instance.grafana,
    ]
  create_duration = "30s"
}

// Recurso para lanzar ansible
resource "null_resource" "local_null" {
  depends_on = [
     time_sleep.Esperamos_30s
    ]

  provisioner "local-exec" {
    command ="ansible-galaxy collection install community.grafana"
  }

  provisioner "local-exec" {
    command ="AWS_PROFILE=${var.profile} ansible-playbook -i inventory  main.yml --user ${var.ansible_user} --key-file=./private_key.pem"
  }

}
