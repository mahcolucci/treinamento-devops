#!/bin/bash

cd 200-pipeline_jenkins/terraform
~/terraform init
~/terraform fmt
~/terraform apply -auto-approve

echo "Aguardando criação de maquinas ..."
sleep 30 # 30 segundos

echo $"[ec2-pipeline-jenkins]" > ../ansible/hosts # cria arquivo
echo "$(~/terraform output | grep public_dns | awk '{print $2;exit}')" | sed -e "s/\",//g" >> ../ansible/hosts 

echo "Aguardando criação de maquinas ..."
sleep 30 # 30 segundos

cd ../ansible

echo "Executando ansible ::::: [ ansible-playbook -i hosts provisionar.yml -u ubuntu --private-key /var/lib/jenkins/.ssh/id_rsa ]"
sudo ansible-playbook -i hosts provisionar.yml -u ubuntu --private-key ~/.ssh/id_rsa

