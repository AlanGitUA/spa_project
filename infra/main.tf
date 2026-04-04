# ============================================================
# Innovatech Chile - POC Lift & Shift AWS
# Arquitectura de 3 capas: Frontend, Backend, Data
# VPC 10.0.0.0/16 | Subred Pública + Privada
# ============================================================

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------
# VPC - Red principal 10.0.0.0/16
# ------------------------------------------------------------

resource "aws_vpc" "innovatech_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "innovatech-vpc"
    Project = "POC-LiftAndShift"
  }
}

# ------------------------------------------------------------
# SUBREDES
# ------------------------------------------------------------

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.innovatech_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "innovatech-public-frontend"
    Tier = "Frontend"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.innovatech_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "innovatech-private-backend-data"
    Tier = "Backend-Data"
  }
}

# ------------------------------------------------------------
# INTERNET GATEWAY
# ------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.innovatech_vpc.id

  tags = {
    Name = "innovatech-igw"
  }
}

# ------------------------------------------------------------
# NAT GATEWAY
# ------------------------------------------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "innovatech-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "innovatech-nat-gateway"
  }
}

# ------------------------------------------------------------
# TABLAS DE RUTAS
# ------------------------------------------------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.innovatech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "innovatech-public-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.innovatech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "innovatech-private-rt"
  }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------------------------------------------------
# IAM - LabRole existente de AWS Academy
# ------------------------------------------------------------

data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# ------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------

resource "aws_security_group" "sg_frontend" {
  name        = "innovatech-sg-frontend"
  description = "SG Frontend - HTTP/HTTPS desde Internet, SSH admin"
  vpc_id      = aws_vpc.innovatech_vpc.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administracion"
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

  tags = {
    Name = "innovatech-sg-frontend"
    Tier = "Frontend"
  }
}

resource "aws_security_group" "sg_backend" {
  name        = "innovatech-sg-backend"
  description = "SG Backend - Acceso solo desde Frontend"
  vpc_id      = aws_vpc.innovatech_vpc.id

  ingress {
    description     = "API desde Frontend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  ingress {
    description     = "SSH desde Frontend (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "innovatech-sg-backend"
    Tier = "Backend"
  }
}

resource "aws_security_group" "sg_data" {
  name        = "innovatech-sg-data"
  description = "SG Data - Acceso solo desde Backend"
  vpc_id      = aws_vpc.innovatech_vpc.id

  ingress {
    description     = "MySQL desde Backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }

  ingress {
    description     = "SSH desde Backend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "innovatech-sg-data"
    Tier = "Data"
  }
}

# ------------------------------------------------------------
# LAUNCH TEMPLATES
# ------------------------------------------------------------

resource "aws_launch_template" "lt_frontend" {
  name          = "innovatech-lt-frontend"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_frontend.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    yum install -y git
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head><title>Innovatech Chile - Frontend</title></head>
    <body>
      <h1>Innovatech Chile - Capa Frontend</h1>
      <p>Servidor web operativo - Arquitectura Lift and Shift</p>
    </body>
    </html>
HTML
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "innovatech-frontend"
      Tier    = "Frontend"
      Project = "POC-LiftAndShift"
    }
  }
}

resource "aws_launch_template" "lt_backend" {
  name          = "innovatech-lt-backend"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_backend.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    yum install -y git
    yum install -y python3 python3-pip
    pip3 install flask
    mkdir -p /opt/backend
    cat > /opt/backend/app.py <<'PYTHON'
    from flask import Flask, jsonify
    app = Flask(__name__)

    @app.route('/health', methods=['GET'])
    def health():
        return jsonify({"status": "ok", "service": "backend", "company": "Innovatech Chile"})

    @app.route('/api/data', methods=['GET'])
    def get_data():
        return jsonify({"message": "Conexion Backend activa", "tier": "Backend"})

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=8080)
PYTHON
    cat > /etc/systemd/system/backend-api.service <<'SERVICE'
    [Unit]
    Description=Innovatech Backend API
    After=network.target
    [Service]
    Type=simple
    User=ec2-user
    ExecStart=/usr/bin/python3 /opt/backend/app.py
    Restart=always
    [Install]
    WantedBy=multi-user.target
SERVICE
    systemctl daemon-reload
    systemctl enable backend-api
    systemctl start backend-api
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "innovatech-backend"
      Tier    = "Backend"
      Project = "POC-LiftAndShift"
    }
  }
}

resource "aws_launch_template" "lt_data" {
  name          = "innovatech-lt-data"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_data.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    yum install -y git
    yum install -y mariadb105-server
    systemctl start mariadb
    systemctl enable mariadb
    mysql -u root <<'MYSQL'
    CREATE DATABASE IF NOT EXISTS innovatech_db;
    CREATE USER IF NOT EXISTS 'innovatech_user'@'10.0.2.%' IDENTIFIED BY 'P@ssw0rd2025!';
    GRANT ALL PRIVILEGES ON innovatech_db.* TO 'innovatech_user'@'10.0.2.%';
    FLUSH PRIVILEGES;
    USE innovatech_db;
    CREATE TABLE IF NOT EXISTS health_check (
      id INT AUTO_INCREMENT PRIMARY KEY,
      status VARCHAR(50) DEFAULT 'active',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO health_check (status) VALUES ('Database operativa - Innovatech Chile');
MYSQL
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "innovatech-data"
      Tier    = "Data"
      Project = "POC-LiftAndShift"
    }
  }
}

# ------------------------------------------------------------
# INSTANCIAS EC2
# ------------------------------------------------------------

resource "aws_instance" "frontend" {
  launch_template {
    id      = aws_launch_template.lt_frontend.id
    version = "$Latest"
  }
  subnet_id = aws_subnet.public_subnet.id
  tags = {
    Name    = "innovatech-frontend"
    Tier    = "Frontend"
    Project = "POC-LiftAndShift"
  }
}

resource "aws_instance" "backend" {
  launch_template {
    id      = aws_launch_template.lt_backend.id
    version = "$Latest"
  }
  subnet_id = aws_subnet.private_subnet.id
  tags = {
    Name    = "innovatech-backend"
    Tier    = "Backend"
    Project = "POC-LiftAndShift"
  }
}

resource "aws_instance" "data" {
  launch_template {
    id      = aws_launch_template.lt_data.id
    version = "$Latest"
  }
  subnet_id = aws_subnet.private_subnet.id
  tags = {
    Name    = "innovatech-data"
    Tier    = "Data"
    Project = "POC-LiftAndShift"
  }
}
