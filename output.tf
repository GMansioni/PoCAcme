
//Pendiente de mejorar

//output "AWS-security" {
//  value = "${aws_security_group.allow_ssh_http.name}"
//}

//output "Vpc" {
//  value = "${aws_vpc.acmevpc.id}"
//}

output "AWS-instance-Web-IP" {
  value = "${aws_instance.web.public_ip}"
}

output "AWS-instance-Grafana-IP" {
  value = "${aws_instance.grafana.public_ip}"
}



resource "local_file" "ansible_inventory_hosts" {
  content = templatefile("inventory.template",
  {
  web_public_ip = aws_instance.web.public_ip,
  web_id = aws_instance.web.id,
  grafana_public_ip = aws_instance.grafana.public_ip,
  grafana_id = aws_instance.grafana.id
  })
  filename = "inventory"
}

output "URLs" {
  value = " Web: http://${aws_instance.web.public_ip}/ \n Grafana: http://${aws_instance.grafana.public_ip}:3000/"
}
