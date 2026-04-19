[db]
%{ for ip in ubuntu_ips ~}
${ip} ansible_user=ubuntu
%{ endfor ~}

[mtn]
%{ for ip in redhat_ips ~}
${ip} ansible_user=ec2-user
%{ endfor ~}

[dev-web]
%{ for ip in amazon_linux_ips ~}
${ip} ansible_user=ec2-user
%{ endfor ~}

[all:vars]
ansible_ssh_private_key_file=~/.ssh/ansible0404.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'