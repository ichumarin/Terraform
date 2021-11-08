output "jenkins_login_url" {
  description = "Jenking login HOST"
  value = aws_instance.r1soft_server.public_ip
}
output "login_credentials" {
  description = "Login Credentials"
  value = "user_name: admin    password: redhat"
}