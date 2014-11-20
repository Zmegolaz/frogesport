-- New in version 1.8

--
-- Table structure for table `clanmembers`
--

DROP TABLE IF EXISTS `clanmembers`;
CREATE TABLE `clanmembers` (
  `cmid` int(11) NOT NULL AUTO_INCREMENT,
  `clme_clid` int(11) NOT NULL,
  `clme_uid` int(11) NOT NULL,
  `clme_member` enum('yes','no') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'no',
  `clme_admin` enum('yes','no') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'no',
  `clme_joined` int(11) NOT NULL,
  PRIMARY KEY (`cmid`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clans`
--

DROP TABLE IF EXISTS `clans`;
CREATE TABLE `clans` (
  `clid` int(11) NOT NULL AUTO_INCREMENT,
  `clan_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `clan_created` int(11) NOT NULL,
  `clan_createdby` int(11) NOT NULL,
  PRIMARY KEY (`clid`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
