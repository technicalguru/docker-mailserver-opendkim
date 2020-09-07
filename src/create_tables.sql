CREATE TABLE IF NOT EXISTS `dkim_keys` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`domain_name` VARCHAR(255) NOT NULL,
	`selector` VARCHAR(63) NOT NULL,
	`private_key` TEXT NOT NULL,
	`public_key` TEXT NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `uk_selector` (`domain_name`,`selector`),
	INDEX `domain_name_idx` (`domain_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='OpenDKIM - Signing Keys';

CREATE TABLE IF NOT EXISTS `dkim_signing` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`author` VARCHAR(255) NOT NULL,
	`dkim_id` INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `uk_author` (`author`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='OpenDKIM - Signing Key Mappings';

CREATE TABLE IF NOT EXISTS `ignore_list` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`hostname` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `uk_hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='OpenDKIM - hostnames to ignore when signing/verifying';
INSERT INTO `ignore_list` (`id`, `hostname`) VALUES (NULL, '127.0.0.1'), (NULL, 'localhost'); 

CREATE TABLE IF NOT EXISTS `internal_hosts` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`hostname` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `uk_hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='OpenDKIM - trusted hosts when signing/verifying';
INSERT INTO `internal_hosts` (`id`, `hostname`) VALUES (NULL, '127.0.0.1'), (NULL, 'localhost'); 
