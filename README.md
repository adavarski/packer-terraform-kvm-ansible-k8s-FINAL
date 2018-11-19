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

##### Packer and Terraform

Download and install packer and terraform 

```Terraform Setup Env:

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
```

Run Shell:
```
 $ packer.sh ---> creates ./image/ubuntu from ubuntu cloud image 
 $ packer-packages.sh to build image with packages installed (python-minimal, ansible) 
 $ packer-packages-ansible.sh to build and provision with ansible-local *docker, kubectl, kubeadm, etc ...and setup host for k8s... if you use this script you have to change ansible/site.yml file and remove:
 
- name: prepare all
  hosts: all
  become: True
  gather_facts: True
  roles:
    - { role: 'prepare', tags: 'prepare' }
 
 also remove from cloud_init.cfg
 
package_update: true
packages:
- python-minimal

We will inject ssh key with terraform for different k8s cluster
 

 $ terraform init; terrafrorm apply ---> create 3 k8s VM from ./image/ubuntu, uses cloud-init 
 to setup networking, public key and install python-minimal ... sudo is working for user ubuntu
 
 Restart VMs because of machine-id bug --- cloud-init: rm /etc/machine-id
 
$ for DOM in `virsh list|grep k8s|awk '{print $2}'`; do virsh shutdown $DOM;done
for DOM in `virsh list --all|grep k8s|awk '{print $2}'`; do virsh start $DOM;done


```


##### Libvirt/KVM
3. Linux bridge, KVM Vifs in bridged mode: the VMs draw their IPs from the physical LAN

Get nodes IPs

Example:
```
$ for i in {000,001,002}; do virsh domifaddr k8s$i;done
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


$ sudo apt install sshpass

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
