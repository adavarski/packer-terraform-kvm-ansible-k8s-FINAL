################################
# Auto-Cloud Terraform Builder #
################################
# Libvirt provider #
##################################


provider "libvirt" { uri = "qemu:///system" }

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

data "template_file" "network_config" {
  template = "${file("${path.module}/network_config.cfg")}"
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-k8s.iso"
  user_data      = "${data.template_file.user_data.rendered}"
  network_config = "${data.template_file.network_config.rendered}"
}

resource "libvirt_volume" "k8s-disk" {
  count = 3 
  name = "k8s00${count.index}.qcow2"
  source = "./image/ubuntu"
}

resource "libvirt_domain" "kubernetes" {
  count = 3 
  name = "k8s00${count.index}"
  memory = "512"
  vcpu = 1

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  disk { volume_id = "${element(libvirt_volume.k8s-disk.*.id, count.index)}" }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
