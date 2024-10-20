provider "aws" {
    region = "ap-south-1"
  
}

variable "cidr" {
    default = "10.0.0.0/16"
  
}

resource "aws_key_pair" "remote-exec" {
    key_name = "ssh_access"
    public_key = file("C:/Users/prade/.ssh/id_rsa.pub")
  
}
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr

}
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "websg" {
  name = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port   = 22
  }
  ingress {
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "mywebapp" {
    ami = "ami-0dee22c13ea7a9a67"
    instance_type = "t2.micro"
    key_name = aws_key_pair.remote-exec.key_name
    vpc_security_group_ids = [aws_security_group.websg.id]
    subnet_id = aws_subnet.sub1.id

    connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("C:/Users/prade/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
    }




  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}