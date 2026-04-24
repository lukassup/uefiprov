#!/usr/bin/env bash
set -euo pipefail

# Copy EFI vars template
cp -v /usr/share/edk2/x64/OVMF_VARS.4m.fd OVMF_VARS.4m.fd

# Setup bridge interface
#sudo ip link add name br0 type bridge
#sudo ip link set dev br0 up
#sudo ip address add 10.0.2.0/24 dev br0

qemu-img create -f qcow2 uefiboot.qcow2 25G

sudo qemu-system-x86_64 \
  -m 4096 \
  -smp sockets=1,cores=4 \
  -cpu host \
  -accel kvm \
  -machine q35,hpet=off \
  -global driver=cfi.pflash01,property=secure,value=on \
  -drive file=/usr/share/edk2/x64/OVMF.4m.fd,if=pflash,format=raw,unit=0,readonly=on \
  -drive file=OVMF_VARS.4m.fd,if=pflash,format=raw,unit=1 \
  -fw_cfg name=opt/org.tianocore/IPv4PXESupport,string=no \
  -fw_cfg name=opt/org.tianocore/IPv6PXESupport,string=no \
  -fw_cfg name=etc/edk2/https/cacerts,file=/etc/ca-certificates/extracted/edk2-cacerts.bin \
  -device virtio-rng-pci \
  -rtc base=utc,clock=host \
  -netdev bridge,br=virbr0,id=net0 \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:23:e2:aa \
  -drive file=uefiboot.qcow2,index=0,if=virtio,media=disk,cache=unsafe \
  -snapshot
  #-serial stdio \
  #-display none \
