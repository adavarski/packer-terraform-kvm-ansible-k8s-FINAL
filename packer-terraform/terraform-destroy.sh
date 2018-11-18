#!/bin/bash

terraform destroy -state=./state/k8s-node1
terraform destroy -state=./state/k8s-node2
terraform destroy -state=./state/k8s-node3
