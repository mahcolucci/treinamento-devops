cd 0-terraform
~/terraform/terraform init
~/terraform/terraform fmt
~/terraform/terraform apply -auto-approve

echo $"[ec2-jenkins]" > ../1-ansible/hosts # cria arquivo
echo "$(~/terraform/terraform output | grep public_dns | awk '{print $2;exit}')" | sed -e "s/\",//g" >> ../1-ansible/hosts 

echo "Aguardando criação de maquinas ..."
sleep 30 # 30 segundos

cd ../1-ansible
ansible-playbook -i hosts provisionar.yml -u ubuntu --private-key ~/.ssh/id_rsa
