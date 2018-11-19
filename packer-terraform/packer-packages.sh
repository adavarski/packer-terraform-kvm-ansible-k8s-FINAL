#!/bin/bash
###########################
# Auto-cloud Build Script #
###########################
sudo apt install -y cloud-utils
cloud-localds ./cloud.img ./cloud.cfg
packer build template-with-packages.json
