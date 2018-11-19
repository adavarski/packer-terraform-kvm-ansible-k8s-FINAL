https://gist.github.com/summerwind/b73d0f72df98fdb6c76e0f2e9ce3971e#file-build-a-os-image-with-packer-and-qemu-md

Build a OS image with QEMU and Ubuntu Cloud Image

Prerequirements

Packer
QEMU
Docker
Build an image of cloud-init settings

$ docker run -it -v `pwd`:/tmp/host --rm ubuntu:16.04
# apt update
# apt install -y vim cloud-utils
# cloud-localds /tmp/host/cloud.img /tmp/host/cloud.cfg
Build a OS image with Packer

$ packer build template.json
Raw
 cloud.cfg
#cloud-config
password: ubuntu
ssh_pwauth: true
chpasswd:
  expire: false
Raw
 template.json
{
  "builders":
  [
    {
      "type": "qemu",
      "iso_url": "ubuntu-16.04-server-cloudimg-amd64-disk1.img",
      "iso_checksum": "3a4b7f6115ca074c4728e4628ca73160e6b7ef6995db3c382015545940568939",
      "iso_checksum_type": "sha256",
      "disk_image": true,
      "output_directory": "image",
      "disk_size": 5000,
      "format": "qcow2",
      "disk_compression": true,
      "headless": true,
      "accelerator": "none",
      "ssh_username": "ubuntu",
      "ssh_password": "ubuntu",
      "ssh_port": 22,
      "ssh_wait_timeout": "300s",
      "vm_name": "ubuntu",
      "use_default_display": true,
      "qemuargs": [
        ["-m", "2048M"],
        ["-smp", "2"],
        ["-fda", "cloud.img"],
        ["-serial", "mon:stdio"]
      ]
    }
  ]
}
 @splashx
splashx commented on Aug 5, 2017
Have you by chance been successful with this setup? The boot runs but packer is unable to ssh into the box.

2017/08/05 14:49:02 ui error: ==> qemu: Error waiting for SSH: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none], no supported methods remain
==> qemu: Error waiting for SSH: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none], no supported methods remain
