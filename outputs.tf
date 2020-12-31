output "Jenkins-Main-Node-Public-IP" {
  value = aws_instance.jenkins-master.public_ip
}

output "Jenkins-Worker-Public-IPs" {
  value = {
    for instance in aws_instance.jenkins-worker-ohio :
    instance.id => instance.public_ip

  }

}

#add LB DNS name to outputs#

output "LB-DNS-NAME" {
  value = aws_lb.application-lb.dns_name

}
