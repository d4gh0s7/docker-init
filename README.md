# CentOS Docker Init
Init shell script for a basic CentOS Docker node, fairly hardened and *almost* production ready out of the box.

>*"Assume every network you're on is malicious"*
>							- Samy Kamar

## 0x00. Before you start
**This project is open source.** I'm assuming *you're smart enough* to read carefully the source code ***before pulling and running the whole thing*** on your system.

### 0x01. Get and execute the script
Get the script and run it as shown:

```vim
curl -O https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/init-system.sh
sudo chmod +x init-system.sh
sudo ./init-system.sh
```

### 0x02. Once the system init is completed
This code is meant to initialize and provision a *very specific*, even though *annoyingly common* environment.
Remember to log into your freshly carded instance, **check that everything is working as expected** and **run the proper hardening**, otherwise... 
```
¯\_(ツ)_/¯

/dev/null before dishonour
```

### 0x03. What do you _really_ need to know _and to do_
- Once you reoot the system, the ssh port won't be `22`, as well as the firewalld related service.
- ***umask*** is set to `077`.
- The sshd config still allows ***_root_*** login. This is meant to allow *specific* provisioning steps. Change it.
- `aide`is installed nut not configured.
- Check the what's in the toolbox `ls -l /opt/toolbox`.
- The kernel is _slightly_ ***hardened***. This might ~~break your things~~. Check it and tune it as needed: `cat /etc/sysctl.d/99-sysctl.conf`.
#### Remember:
```
		+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+
		|I|n| |C|o|m|m|o|n|l|y| |u|s|e|d| |P|a|s|s|w|o|r|d|s| |W|e| |T|r|u|s|t|
		+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+
```
Generate randomized password to protect your systems, [grc](https://www.grc.com/passwords.htm) has a pretty decent tool for the purpose.

Authenicate users ***always*** using keys and _possibly_ set the `2FA` for your ssh accounts.