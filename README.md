# docker-mailserver-opendkim
This is a Docker image for an OpenDKIM milter server. The project is part of the 
[docker-mailserver](https://github.com/technicalguru/docker-mailserver) project but can run separately 
without the other components. However, a database server is always required to store keys and configuration. 

Related images:
* [docker-mailserver](https://github.com/technicalguru/docker-mailserver) - The main project, containing composition instructions
* [docker-mailserver-postfix](https://github.com/technicalguru/docker-mailserver-postfix) - Postfix/Dovecot image (mailserver component)
* [docker-mailserver-postfixadmin](https://github.com/technicalguru/docker-mailserver-postfixadmin) - Image for PostfixAdmin (Web UI to manage mailboxes and domain in Postfix)
* [docker-mailserver-amavis](https://github.com/technicalguru/docker-mailserver-amavis) - Amavis, ClamAV and SpamAssassin (provides spam and virus detection)
* [docker-mailserver-roundcube](https://github.com/technicalguru/docker-mailserver-roundcube) - Roundcube Webmailer

# Tags
The following versions are available from DockerHub. The image tag matches the Postfix version.

* [2.11.0.6, 2.11.0, 2.11, 2, latest](https://github.com/technicalguru/docker-mailserver-opendkim/tree/v2.11.0.6) - [Dockerfile](https://github.com/technicalguru/docker-mailserver-opendkim/blob/2.11.0.6/Dockerfile)

# Features
* Bootstrap from scratch: See more information below.
* DKIM signing and verification
* Key creation (under development, see open issues)
* Key storage in database

# License
_docker-mailserver-opendkim_  is licensed under [GNU LGPL 3.0](LICENSE.md). As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

# Prerequisites
The following components must be available at runtime:
* [MySQL >8.0](https://hub.docker.com/\_/mysql) or [MariaDB >10.4](https://hub.docker.com/\_/mariadb) - used as database backend for domains and mailboxes. 

# Usage

## Environment Variables
_mailserver-opendkim_  requires various environment variables to be set. The container startup will fail when the setup is incomplete.

| **Variable** | **Description** | **Default Value** |
|------------|---------------|-----------------|
| `DKIM_SETUP_PASS` | The password of the database administrator (`root`). This value is required for the initial bootstrap only in order to setup the database structure. It can and shall be removed after successful setup. |  |
| `DKIM_DB_HOST` | The hostname or IP address of the database server | `localhost` |
| `DKIM_DB_USER` | The name of the database user. **Attention!** You shall not use an administrator account. | `opendkim` |
| `DKIM_DB_PASS` | The password of the database user | `opendkim` |
| `DKIM_DB_NAME` | The name of the database | `opendkim` |
| `DKIM_DOMAIN` | The first and primary mail domain of this server. | `localdomain` |
| `DKIM_PORT` | The milter port the docker image shall offer its service | `41001` |

## Ports
_docker-mailserver-opendkim_ exposes 2 ports by default:
* Port 80 - A webserver port that will provide a Key Management service in later stages. Currently it does not provide anything but a static page.
* Port 41001 - the DKIM signing and verification port
 
## Running the Container
The [main mailserver project](https://github.com/technicalguru/docker-mailserver) has examples of container configurations:
* [with docker-compose](https://github.com/technicalguru/docker-mailserver/tree/master/examples/docker-compose)
* [with Kubernetes YAML files](https://github.com/technicalguru/docker-mailserver/tree/master/examples/kubernetes)
* [with HELM charts](https://github.com/technicalguru/docker-mailserver/tree/master/examples/helm-charts)

## Bootstrap and Setup
Once you have started your OpenDKIM container successfully, it is now time to create your DKIM signing keys for each domain. This is what you need to do:

1. Login to the container by executing `/bin/bash` interactively on the container.
1. For each of your domains `DOMAIN` perform the following steps:
    1. Create a temporary directory: `mkdir /etc/opendkim/keys/$DOMAIN`
    2. Create the actual key: `opendkim-genkey -b 2048 -d $DOMAIN -D /etc/opendkim/keys/$DOMAIN -s default -v`. You will find public and private key in the temporary directory.
    3. Insert public and private key into your database by signing in: `mysql -u opendkim -p opendkim` and enter your database password.
       Then enter these SQL statement and hit enter for each of them:

        ```
        INSERT INTO `dkim_keys` (`domain_name`, `selector`, `private_key`, `public_key`) VALUES ('$DOMAIN', 'default', '-----BEGIN RSA PRIVATE KEY-----\r\n***$YOUR_PRIVATE_KEY*** \r\n-----END RSA PRIVATE KEY-----', '-----BEGIN RSA PUBLIC KEY-----\r\n***$YOUR_PUBLIC_KEY***-----END RSA PUBLIC KEY-----');`
        SELECT `id` FROM `dkim_keys` WHERE `domain_name` = '$DOMAIN'; 
        INSERT INTO `dkim_signing` (`author`, `dkim_id`) VALUES ('$DOMAIN', $KEYID_FROM_SELECT);
        INSERT INTO `ignore_list` (`hostname`) VALUES ('*@$DOMAIN');
        INSERT INTO `internal_hosts` (`hostname`) VALUES ('*@$DOMAIN');
        ```

    4. Insert the *Public Key* as described by step 2 output into your DNS TXT record for the domain. It can look like this:

        ```
        v=DKIM1; h=sha256; k=rsa; p=***PUBLIC_KEY_WITHOUT_SPACE_OR_NEWLINE***
        ```

       The TXT record needs to be named `default._domainkey.$DOMAIN` - the `default` can be varied when using a different value in SQL statement in step 3. This would enable
       you to use different keys e.g. for subdomains and individual mail addresses. You would need to change the SQL commands accordingly (Table `dkim_keys` decides
       which key will be used. You can use full mail addresses in column `author` then.)

# Additional OpenDKIM customization
You can further customize the OpenDKIM configuration files. Please follow these instructions:

1. Check the `/usr/local/mailserver/templates` folder for already existing customizations. 
1. Customize your OpenDKIM configuration file.
1. Provide your customized file back into the appropriate template folder at `/usr/local/mailserver/templates` by using volume mappings.
1. (Re)Start the container. If you configuration was not copied correctly then log into the container (bash is available) and issue `/usr/local/mailserver/reset-server.sh`. Then restart again.

# Testing your DKIM setup.

Here are some useful links that help you to test whether your DKIM setup works as intended:

* [**DMARC DKIM Record Checker**](https://www.dmarcanalyzer.com/how-to-validate-a-domainkey-dkim-record/) - checks correctness of your DNS TXT entry
* [**DKIM Check**](https://www.appmaildev.com/en/dkim) - verifies your DKIM signing feature by giving you a temporary recipient address where you send a test mail

# Issues
This Docker image is mature in its DKIM signing and verification feature. However, creation of DKIM keys is still cumbersome and needs to be improved. A web page service is planned to ease that step.

# Contribution
Report a bug, request an enhancement or pull request at the [GitHub Issue Tracker](https://github.com/technicalguru/docker-mailserver-opendkim/issues). Make sure you have checked out the [Contribution Guideline](CONTRIBUTING.md)
