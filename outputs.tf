# output "subnet_tests" {
#     value = aws_subnet.subnets
# }

output "subnet_count" {
    value = length(aws_subnet.subnets)
}

output "Web_ips" {
    value = flatten(concat(aws_instance.WebServer.*.public_ip[*]))
}

output "jenkins_homepage" {
    value = [ join(",", [for ip in aws_instance.AppServer.*.public_ip: "http://${ip}:8080\n"]) ]
}