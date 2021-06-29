apt update
ssh-keygen -f /root/.ssh/id_rsa -q -N ""
apt-get install -y software-properties-common
apt-add-repository -y ppa:ansible/ansible
apt update
apt-get install -y ansible

# only managed node
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
apt install -y python3-pip
pip install -r requirements.txt
cp -rfp inventory/sample inventory/k8scluster

# declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
# CONFIG_FILE=inventory/k8scluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
# # Review and change parameters under ``inventory/mycluster/group_vars``
# cat inventory/mycluster/group_vars/all/all.yml
# cat inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# # Deploy Kubespray with Ansible Playbook - run the playbook as root
# # The option `--become` is required, as for example writing SSL keys in /etc/,
# # installing packages and interacting with various systemd daemons.
# # Without --become the playbook will fail to run!
# ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml
