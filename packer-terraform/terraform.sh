#!/bin/bash

terraform init

cp k8s-node1.tf.TMP k8s-node1.tf
terraform apply -state=./state/k8s-node1
rm k8s-node1.tf

cp k8s-node2.tf.TMP k8s-node2.tf
terraform apply -state=./state/k8s-node2
rm k8s-node2.tf

cp k8s-node3.tf.TMP k8s-node3.tf
terraform apply -state=./state/k8s-node3
rm k8s-node3.tf
