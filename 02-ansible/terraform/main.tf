provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-09e67e426f25ce0d7" #data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  # instance_type= var.tamanho
  subnet_id = "subnet-0dbc6439c94e66d76"
  # subnet_id= var.subnet_id
  # count= var.quantidade
  associate_public_ip_address = true
  key_name                    = "kp-colucci"
  vpc_security_group_ids      = ["${aws_security_group.permitir_ssh.id}"]
  tags = {
    Name = "maquina-ansible-colucci"
    # Name = "${var.nome}-(${count.index})"
  }

  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:546785272719:key/6f1fc66a-b046-4288-a319-4d6fa9c4808a"
    volume_size = 20
  }
}


