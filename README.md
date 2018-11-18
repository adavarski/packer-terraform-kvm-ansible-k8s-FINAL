# ENV: Ubuntu 18.04, KVM

# home-cloud setup
Automatically provision a fully customizable and production-worthy cloud<br>

#### Used (2018)
- Packer : Automated OS builds using QEMU
- Terraform : Automated builds against any orchestration or virtualization engine
- Libvirt/KVM : Production quality Virtual Machine deployments
- Kubernetes : Container orchestration and automation
- Calico : Firewalling and Namespace control
- MetalLB : Your own private cloud with External IPs and Load Balancers for Kubernetes
- Minio : Incredible Object Storage from the maker of GlusterFS
- GitLab : Code storage and CI/CD with GitLab Pipelines
- ElasticSearch, LogStash, Kibana : Log aggregation, indexing and beautiful visualization

##### Packer
1. Download ISO and build custom image from preseed.cfg. Using Qemu!

 $ packer.sh 

TODO1: add python-minimal and cloud-init to file ubuntu-xenial-nodes.tf or preceed.cfg file, setup sudoers: ubuntu ALL=(ALL) NOPASSWD: ALL, add your public key to ubuntu user authorized_keys, implement /ansible/roles/prepare/tasks into base image (install docker, k8s, and setup k8s env)

```
"provisioners": [{
    "type": "shell",
    "inline": [
   
      "sudo apt-get update",
      "sudo apt-get install -y python-minimal cloud-init",
     
    ]
  }  
```  
##### Terraform
2. Use the custom image to boot three VMs (the image can also be pushed to bare-metal in raw format)

Setup ENV:

$ systemctl stop/disable apparmor

/etc/libvirt/qemu.conf --> security_driver = "none" ; user = "root" ; group = "kvm" ---> systemctl restart libvirtd

Installing Terraform libvirt Provider:

$ sudo apt install golang-go 

$ export GOPATH=$HOME/go

$ go get github.com/dmacvicar/terraform-provider-libvirt
$ go install github.com/dmacvicar/terraform-provider-libvirt

You will now find the binary at $GOPATH/bin/terraform-provider-libvirt

$ terraform init ---> create $HOME/.terraform.d

$ cd $HOME/.terraform.d; mkdir plugins; cp $GOPATH/bin/terraform-provider-libvirt $HOME/.terraform.d/plugins

$ cd terraform

$ terraform init

$ terraform apply

TODO2: Add private key via cloud-init if you don't add via packer
``` 
----- add to file ubuntu-xenial-nodes.tf
 data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

-----new file cloud_init.cfg
#cloud-config
ssh_authorized_keys:
  - ssh-rsa mR7XxKmAM/+SJw0jww+7Rq/Ds0+wDAj+wNc1RczI5C2wZ6ydML2RM6IaA14LS8
```  
##### Libvirt/KVM
3. Linux bridge, KVM Vifs in bridged mode: the VMs draw their IPs from the physical LAN

Get nodes IPs

Example:
```
$ for i in {000,001,002}; do virsh domifaddr ubuntu$i;done
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet2      1e:77:aa:f9:29:42    ipv4         192.168.122.248/24

 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet0      2a:14:a4:00:ae:5c    ipv4         192.168.122.92/24

 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet1      8e:b2:8b:17:f6:9e    ipv4         192.168.122.9/24
```
##### Ansible
4. Use Ansible to deploy Kubernetes cluster onto the VMs

Create inventory (IPs of KVM VMs)
```
Example:
$ cat ansible/inventory 
[all]
192.168.122.248
192.168.122.92
192.168.122.9
[masters]
192.168.122.248
[nodes]
192.168.122.92
192.168.122.9

for i in VMs ssh ubuntu@VM_IP "apt install python-minimal" if not provisioned via packer

Setup keys and sudo:

$ sudo apt install sshpass

$ ansible-playbook -i ./inventory send_keys.yml  --ask-pass --ask-sudo-pass

Setup k8s 

Edit ansible/roles/master/tasks/init.yml and change master IP .... lines: 

kubeadm init --apiserver-advertise-address=192.168.122.248 --pod-network-cidr=10.244.0.0/16

| sed -e 's!clusterCIDR: ""!clusterCIDR: "192.168.122.0/24"!' >/etc/kubectl/kube-proxy.map

Run K8s playbook

$ ansible-playbook site.ym
```

##### Kubernetes
5. Use Calico for Network Firewalling and Namespace control
6. Deploy MetalLB in ARP mode to provide external IPs (Load Balancer) for the cluster! (siick)

##### Minio
7. Deploy Minio into the cluster for AWS S3 Object-like Storage


#### Customization Required
8. Deploy GitLab
- https://docs.gitlab.com/ee/install/kubernetes/gitlab_chart.html
9. Deploy ELK Stack into the cluster
- https://github.com/kayrus/elk-kubernetes
