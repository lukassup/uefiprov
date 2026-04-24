#!/usr/bin/env bash
set -euo pipefail

##
# Dependencies
# 
# brew install qemu nginx dnsmasq
#

# Get the installation ISO
curl -LOC- https://ftp.fau.de/rockylinux/9.7/isos/aarch64/Rocky-9-latest-aarch64-minimal.iso
mkdir -p iso
hdiutil attach Rocky-9-latest-aarch64-minimal.iso -mountpoint iso -imagekey diskimage-class=CRawDiskImage -quiet -nobrowse -readonly

# Prepare files for netboot
ln -fs iso/images .
cp -r iso/EFI .
chmod -R a+rX EFI
cp -f grub.aarch64.cfg EFI/BOOT/grub.cfg

FW_CODE="$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd"
FW_VARS="$(brew --prefix qemu)/share/qemu/edk2-arm-vars.fd"

# Copy EFI vars template and setup scrath rootdisk image
cp $FW_VARS tmp-efivars.fd
qemu-img create -q -f qcow2 tmp-root.qcow2 25G

# Networking setup
echo '==> Run: ./setup-macos.sh'
echo '==> Run: sudo dnsmasq -C dnsmasq.conf'
echo '==> Run: sudo nginx -p . -c nginx.conf'

# Disable '-snapshot' & '-drive ...,cache=unsafe' option for persistence
sudo qemu-system-aarch64  \
  -m 4G \
  -smp sockets=1,cores=4 \
  -cpu host \
  -accel hvf \
  -machine virt,iommu=smmuv3 \
  -drive file=${FW_CODE},if=pflash,format=raw,unit=0,readonly=on \
  -drive file=${FW_VARS},if=pflash,format=raw,unit=1 \
  -fw_cfg name=opt/org.tianocore/IPv4PXESupport,string=no \
  -fw_cfg name=opt/org.tianocore/IPv6PXESupport,string=no \
  -drive file=tmp-root.qcow2,index=0,if=virtio,media=disk,cache=unsafe \
  -rtc base=utc,clock=host \
  -device virtio-rng-pci \
  -device virtio-gpu \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-tablet \
  -display default \
  -netdev vmnet-host,id=net0,net-uuid=c1131777-7ef9-44f8-9094-1ae3e414ec37 \
  -device virtio-net,netdev=net0 \
  -snapshot
