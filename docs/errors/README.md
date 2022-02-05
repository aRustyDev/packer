<!-- # https://forum.proxmox.com/threads/using-packer-to-deploy-ubuntu-20-04-to-proxmox.104275/ -->
<!-- # https://askubuntu.com/questions/1391042/using-packer-to-deploy-ubuntu-20-04-to-proxmox -->

<!-- # REFERENCES -->
<!-- # https://github.com/canonical/cloud-init/blob/main/cloudinit/sources/DataSourceNoCloud.py -->

<!-- # SIMILAR -->
<!-- # https://askubuntu.com/questions/1362813/cant-run-autoinstall-with-ubuntu-server-20-04 -->
<!-- # https://askubuntu.com/questions/1238070/deploy-ubuntu-20-04-on-bare-metal-or-virtualbox-vm-by-pxelinux-cloud-init-doesn -->


<!-- # nouveau.modeset=0  -->
<!-- # fsck.mode=skip  -->
<!-- # linux /casper/vmlinuz  -->
<!-- # autoinstall ds=nocloud-net;s=http://MyIP/autoinstall/ -->
<!-- # ip=dhcp  -->
<!-- # url=http://192.168.0.144:80/ubuntu-20.04.3-live-server-amd64.iso  -->
<!-- # cloud-config-url=http://MyIp/autoinstall/meta-data — splash nouveau.modeset=0 -->

<!-- # __init__.py[WARNING]: Unhandled non-multipart (text/x-not-multipart) userdata: 'b'utoinstall:'...' -->
<!-- # util.py[DEBUG]: Reading from /var/lib/cloud/seed/nocloud/user-data (quiet=false) -->
<!-- # util.py[DEBUG]: Read 0 bytes from /var/lib/cloud/seed/nocloud/user-data -->
<!-- # util.py[DEBUG]: Attempting to load yaml from string of length 0 with allowed root types -->
<!-- # util.py[WARNING]: Getting data from <class 'cloudinit.sources.DataSourceNoCloud.DataSourceNoCloudNet'> failed -->



<!-- #seed from http://user-data not supported by DataSourceNoCloud [seed=None][dsmode=net] -->
<!-- #/var/lib/cloud/seed/nocloud/user-data came back as blank -->
<!-- #/var/log/cloud-init.log -->
<!-- #/var/log/cloud-init-output.log -->
<!-- # Checked webserver logs /var/log/httpd/ "GET /user-datameta-data" -->


<!-- # https://askubuntu.com/questions/122505/how-do-i-create-a-completely-unattended-install-of-ubuntu -->
<!-- # https://ki1cx.github.io/linux/cryptocurrency/ubuntu-unattended-install/ -->
<!-- # https://github.com/netson/ubuntu-unattended -->