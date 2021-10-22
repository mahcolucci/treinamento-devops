#!/bin/bash

cd terraform
/usr/local/bin/terraform init
/usr/local/bin/terraform fmt
/usr/local/bin/terraform apply -auto-approve

echo "Aguardando criação de maquinas ..."
sleep 30 # 30 segundos

echo $"[ec2-pipeline-jenkins]" > ../ansible/hosts # cria arquivo
echo "$(/usr/local/bin/terraform output | grep public_dns | awk '{print $2;exit}')" | sed -e "s/\",//g" >> ../ansible/hosts 

echo "Aguardando criação de maquinas ..."
sleep 30 # 30 segundos

cd ../ansible

echo "Executando ansible ::::: [ ansible-playbook -i hosts provisionar.yml -u ubuntu --private-key .ssh/id_rsa ]"
sudo ansible-playbook -i hosts provisionar.yml -u ubuntu --private-key ~/.ssh/id_rsa

