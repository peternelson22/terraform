output "dns_name" {
  value       = aws_lb.example.dns_name
  description = "DNS name of LB"
}