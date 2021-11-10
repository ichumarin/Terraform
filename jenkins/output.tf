output "jenkins_server_url" {
  description = "Jenking login HOST"
  value       = "${aws_route53_record.jenkins.name}:8080"
}
output "login_credentials" {
  description = "Login Credentials"
  value       = "To Unlock Jenkins please use administrator password highlited above ^ "
}