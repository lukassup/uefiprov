#!/usr/bin/env bash
set -euo pipefail

##
# Requirements
#
# Packages: libvirt, qemu, nginx
#
# Tested on Arch Linux, but should work on other distributions as well
#
# libvirt is only used as a convenient way of running bridge+nat network with
# dnsmasq. This can alternatively be implemented with utils from iproute2 & dnsmasq

FW_CODE=/usr/share/edk2/x64/OVMF.4m.fd
FW_VARS=/usr/share/edk2/x64/OVMF_VARS.4m.fd
FW_CERTS=/etc/ca-certificates/extracted/edk2-cacerts.bin

# Get the installation ISO
curl -LOC- https://ftp.fau.de/rockylinux/9/isos/x86_64/Rocky-9-latest-x86_64-minimal.iso
mkdir -p iso
mountpoint -q iso || sudo mount -o loop,ro,uid=$USER -t iso9660 Rocky-9-latest-x86_64-minimal.iso iso
ln -sf iso/images .
cp -r iso/EFI .
chmod -R a+rwX EFI
cp grub.amd64.cfg EFI/BOOT/grub.cfg

# Networking setup, this recreates the "default" libvirt network using same
# default but includes additional dnsmasq configuration for UEFI HTTP booting
# In theory AArch64 should also boot but this was not tested
sudo systemctl enable --now libvirtd
sudo virsh -q net-destroy default
sudo virsh -q net-undefine default
sudo virsh -q net-define net-default.xml --validate
sudo virsh -q net-start default

# Copy EFI vars, create scratch rootvol
cp $FW_VARS tmp-efivars.fd
qemu-img create -q -f qcow2 tmp-root.qcow2 25G

echo '==> Run: sudo nginx -p . -c nginx.conf'

# Disable '-snapshot' & '-drive ...,cache=unsafe' option for persistence
sudo qemu-system-x86_64 \
  -m 4096 \
  -smp sockets=1,cores=4 \
  -cpu host \
  -accel kvm \
  -machine q35,hpet=off \
  -global driver=cfi.pflash01,property=secure,value=on \
  -drive file=${FW_CODE},if=pflash,format=raw,unit=0,readonly=on \
  -drive file=tmp-efivars.fd,if=pflash,format=raw,unit=1 \
  -fw_cfg name=opt/org.tianocore/IPv4PXESupport,string=no \
  -fw_cfg name=opt/org.tianocore/IPv6PXESupport,string=no \
  -fw_cfg name=etc/edk2/https/cacerts,file=${FW_CERTS} \
  -device virtio-rng-pci \
  -rtc base=utc,clock=host \
  -netdev bridge,br=virbr0,id=net0 \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:23:e2:aa \
  -drive file=tmp-root.qcow2,index=0,if=virtio,media=disk,cache=unsafe \
  -snapshot
  #-serial stdio \
  #-display none \
