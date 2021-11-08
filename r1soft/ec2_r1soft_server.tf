resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "r1soft_server_tls" {
  name        = var.sec_group_name
  description = "Allow TLS inbound traffic"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
resource "aws_instance" "r1soft_server" {
  ami                    = data.aws_ami.centos.id
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.all.names[0]
  vpc_security_group_ids = [aws_security_group.r1soft_server_tls.id]
  key_name               = aws_key_pair.bastion.key_name
}

resource "null_resource" "commands" {
  depends_on = [aws_instance.r1soft_server, aws_security_group.r1soft_server_tls]
  triggers = {
    always_run = timestamp()
  }
  # Push files to remote server
  provisioner "file" {
    connection {
      host        = aws_instance.r1soft_server.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
    }
    source      = "r1soft.repo"
    destination = "/tmp/r1soft.repo"
  }
  # Execute linux commands on remote machine
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.r1soft_server.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "sudo cp /tmp/r1soft.repo /etc/yum.repos.d/r1soft.repo",
      "sudo yum update -y",
      "sudo yum install r1soft-cdp-enterprise-server -y",
      "sudo r1soft-setup --user admin --pass redhat",
      "sudo systemctl restart cdp-server"
    ]
  }
}