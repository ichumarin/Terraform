output "r1soft_server_ip" {
  description = "R1soft server public IP"
  value = aws_instance.r1soft_server.public_ip
}
output "login_credentials" {
  description = "Login Credentials"
  value = "user_name: admin    password: redhat"
}