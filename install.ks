lang en_US
keyboard --xlayouts='us'
timezone Etc/UTC --utc
rootpw $2b$10$3IM3HIJ7aOJRhGuW.yQAnOeHD0tKXS2mtOosXut6MfoB9q71r4BVm --iscrypted
reboot
text --non-interactive
url --url=http://192.168.122.1/iso/
bootloader --location=boot --append="rhgb quiet"
zerombr
clearpart --all --initlabel
autopart --type=plain --nohome --fstype=xfs
network --bootproto=dhcp
skipx
firstboot --disable
selinux --disabled
%packages
@^minimal-environment
%end
