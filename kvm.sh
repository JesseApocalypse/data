#!/bin/bash
img_dir=/var/lib/libvirt/images/
qemu_dir=/etc/libvirt/qemu/
cd $img_dir
qemu-img create -b .node_base.qcow2 -f qcow2 ${1}.img
cp  .node_base.xml ${qemu_dir}${1}.xml
sed -i "2s/node_base/${1}/" ${qemu_dir}${1}.xml
sed -i "26s/node_base.img/${1}.img/" ${qemu_dir}${1}.xml
virsh define ${qemu_dir}${1}.xml
virsh start ${1}

