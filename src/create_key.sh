
- mkdir /etc/opendkim/keys/<domain>
- create key: opendkim-genkey -b 2048 -d <DOMAIN> -D /etc/opendkim/keys/<DOMAIN> -s default -v
- add record in signing table
- add record in key table
- add record in trusted hosts
- add record in ignored hosts
- ADD default.txt to TXT entries in Nameserver

