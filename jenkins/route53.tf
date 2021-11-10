resource "aws_route53_record" "jenkins" {
  zone_id = "Z08596542MGC2WLA3JHHF"
  name    = "jenkins.ichenterprises.net"
  type    = "A"
  ttl     = "30"
  records = [aws_instance.jenkins_server.public_ip]
}
