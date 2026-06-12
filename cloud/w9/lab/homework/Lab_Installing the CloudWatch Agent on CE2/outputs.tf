output "instance_id" {
  description = "ID of the EC2 instance running the CloudWatch Agent."
  value       = aws_instance.cloudwatch_agent.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.cloudwatch_agent.public_ip
}

output "iam_role_name" {
  description = "IAM role attached to the EC2 instance."
  value       = aws_iam_role.ec2.name
}

output "session_manager_command" {
  description = "AWS CLI command for connecting through Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.cloudwatch_agent.id} --region ${var.aws_region}"
}

output "agent_status_command" {
  description = "Run this command inside the instance to verify the agent."
  value       = "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status"
}
