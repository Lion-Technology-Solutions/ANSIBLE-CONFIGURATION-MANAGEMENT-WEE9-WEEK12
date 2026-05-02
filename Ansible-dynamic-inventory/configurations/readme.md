Setup Ansible AWS Dynamic Inventory
1.	Ensure that python3   and pip3 are installed on your ansible server / ansible master controller 
a.	Confirm python version   :     

 python3 --version 

2.	Step 2: Install the boto3 library. Ansible uses the boot core to make API calls to AWS to retrieve ec2 instance details.

a.	Install pip3
           Sudo apt update 
          sudo apt-get install python3-pip -y


 sudo pip3 install boto3   --break-system-packages
3.	step 3: Create an inventory directory under /opt and cd into the directory.
  sudo mkdir -p /opt/ansible/inventory
          cd /opt/ansible/inventory
4.	Step 4: Create a file named aws_ec2.yaml in the inventory directory.
copy the file aws.ec2.yaml to  /opt/ansible.inventory 
create directory 
   sudo mkdir  /etc/ansible 
  copy ansible.cfg to  /etc/ansible 