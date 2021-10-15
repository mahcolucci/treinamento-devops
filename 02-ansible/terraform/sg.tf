resource "aws_security_group" "permitir_ssh" {
  name        = "permitir_ssh_colucci"
  description = "Permitindo SSH para as maquinas criadas pelo terraform"
  vpc_id      = "vpc-000ac43d9700f2e6c"

  ingress = [
    {
      description      = "Liberando SSH de entrada"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null
    },
    {
      description      = "Liberando SSH de entrada"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null
      description      = "Liberando porta interna pra geral"
    }
  ]

  tags = {
    Name = "permitir_ssh_colucci"
  }
}
