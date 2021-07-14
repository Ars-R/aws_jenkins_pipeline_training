output "instance_id" {
  description = "ID"
  value       = aws_instance.instance.*.id

}

output "instance_public_ip" {
  description = "public ip"
  value       = aws_instance.instance.*.public_ip
}

output "instance_private_ip" {
  description = "privat ip"
  value       = aws_instance.instance.*.private_ip
}

output "DNS" {
  value = aws_instance.instance.*.public_dns
}
/*
output "machines" {
  value = aws_instance.instance.*.arn
}
*/



