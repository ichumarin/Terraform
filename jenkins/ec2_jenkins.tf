resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "jenkins_server_tls" {
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
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
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
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.centos.id
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.all.names[0]
  vpc_security_group_ids = [aws_security_group.jenkins_server_tls.id]
  key_name               = aws_key_pair.bastion.key_name
}

resource "null_resource" "commands" {
  depends_on = [aws_instance.jenkins_server, aws_security_group.jenkins_server_tls, aws_route53_record.jenkins]
  triggers = {
    always_run = timestamp()
  }
  # Push files to remote server
  provisioner "file" {
    connection {
      host        = aws_instance.jenkins_server.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
    }
    source      = "jenkins.repo"
    destination = "/tmp/jenkins.repo"
  }
  # Execute linux commands on remote machine
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.jenkins_server.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "sudo cp /tmp/jenkins.repo /etc/yum.repos.d/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum install epel-release java-11-openjdk-devel -y",
      "sudo yum install jenkins -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl start jenkins",
      "sudo cp /var/lib/jenkins/secrets/initialAdminPassword /tmp/password",
      "echo -e $(tput setaf 1 )'Jenkins Administrotor Password is: '$(tput sgr0) $(tput setaf 2)`sudo cat /tmp/password`$(tput sgr0)",
    ]
  }
}

# resource "null_resource" "admin_password" {
#   depends_on = [null_resource.commands]
#   triggers = {
#     always_run = timestamp()
#   }
#   provisioner "remote-exec" {
#     connection {
#       host        = aws_instance.jenkins_server.public_ip
#       type        = "ssh"
#       user        = "centos"
#       private_key = file("~/.ssh/id_rsa")
#     }
#     inline = [
#         " echo -e $(tput setaf 1 )'Jenkins Administrotor Password is: '$(tput sgr0) $(tput setaf 2)`sudo cat /var/lib/jenkins/secrets/initialAdminPassword`$(tput sgr0)",

#     ]
#   }
# }