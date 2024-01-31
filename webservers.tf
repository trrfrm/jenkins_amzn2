# resource "aws_key_pair" "keypair" {
#   key_name                    = var.webserver_info.key_name
#   public_key                  = file(var.key_path)
# }

resource "aws_instance" "WebServer" {
  count                         = local.count
  ami                           = data.aws_ami.latest-amazon-linux-image.id
  instance_type                 = local.instance_type
  associate_public_ip_address   = local.public_ip_enabled
  key_name                      = local.key_name 
  subnet_id                     = aws_subnet.subnets[count.index].id
  vpc_security_group_ids        = [aws_security_group.Web-SG.id]

  tags                          = {
      Name                      = local.webserver_tags[count.index]
  }
  connection {
    type        = local.connection_type
    user        = local.username
    private_key = file(local.key_path)
    host        = self.public_ip
  }
  provisioner "file" {
    source      = local.jenkins_source
    destination = local.jenkins_destination
  }
  provisioner "remote-exec" {
    inline      = [
      "sudo setfacl -R -m u:$USER:rwx jenkins.sh",
      "sh ~/jenkins.sh",
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]
  }
  depends_on    = [ aws_vpc.vnet, aws_subnet.pub_subnets]
}

resource "null_resource" "WebProvisioner" {
  count          = local.count
  triggers       = {
    exec_trigger = local.hammer
  }
  connection {
    type        = local.connection_type
    user        = local.username
    private_key = file(local.key_path)
    host        = aws_instance.WebServer.*.public_ip[count.index]
  }
  provisioner "remote-exec" {
    inline      = [
      "sudo yum update -y",
      "java -version",
      "terraform --version"
    ]
  }
  depends_on    = [ aws_instance.WebServer ]
}