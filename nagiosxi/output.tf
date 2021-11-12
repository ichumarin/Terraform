output "nagios_server_access" {
  description = "Nagios server public IP"
  value       = "You can access the Nagios XI web interface by visiting: http://${aws_instance.nagios_server.public_ip}/nagiosxi/"
}
