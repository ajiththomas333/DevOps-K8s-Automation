resource "aws_instance" "master" {

  ami           = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.k8s_sg.id
  ]

  user_data = <<-EOF
#!/bin/bash
mkdir -p /home/ubuntu/.ssh
echo "${var.public_key}" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
EOF

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "worker" {


  ami           = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.k8s_sg.id
  ]

  user_data = <<-EOF
#!/bin/bash
mkdir -p /home/ubuntu/.ssh
echo "${var.public_key}" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
EOF

  tags = {
    Name = "k8s-worker"
  }
}
