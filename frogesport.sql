SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `frogesport`
--
CREATE DATABASE IF NOT EXISTS `frogesport` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `frogesport`;

-- --------------------------------------------------------

--
-- Table structure for table `answers`
--

CREATE TABLE IF NOT EXISTS `answers` (
  `aid` int(16) NOT NULL AUTO_INCREMENT,
  `answ_question` int(16) NOT NULL,
  `answ_answer` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`aid`),
  KEY `answ_question` (`answ_question`),
  FULLTEXT KEY `answ_answer` (`answ_answer`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `classes`
--

CREATE TABLE IF NOT EXISTS `classes` (
  `cid` int(16) NOT NULL AUTO_INCREMENT,
  `clas_points` int(16) NOT NULL,
  `clas_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `clas_maxmana` int(16) NOT NULL,
  `clas_comment` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `clas_points` (`clas_points`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `correctanswers`
--

CREATE TABLE IF NOT EXISTS `correctanswers` (
  `caid` int(16) NOT NULL AUTO_INCREMENT,
  `coan_qid` int(16) NOT NULL,
  `coan_uid` int(16) NOT NULL,
  `coan_channel` varchar(200) NOT NULL,
  `coan_answer` varchar(256) NOT NULL,
  `coan_time` decimal(5,3) NOT NULL,
  `coan_date` int(11) NOT NULL,
  PRIMARY KEY (`caid`),
  KEY `coan_uid` (`coan_uid`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

-- --------------------------------------------------------

--
-- Table structure for table `prizes`
--

CREATE TABLE IF NOT EXISTS `prizes` (
  `pid` int(16) NOT NULL AUTO_INCREMENT,
  `priz_inarow` int(16) NOT NULL,
  `priz_prize` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`pid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `questions`
--

CREATE TABLE IF NOT EXISTS `questions` (
  `qid` int(16) NOT NULL AUTO_INCREMENT,
  `ques_category` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `ques_question` varchar(512) COLLATE utf8_unicode_ci NOT NULL,
  `ques_tempid` decimal(16,5) NOT NULL,
  `ques_source` varchar(512) COLLATE utf8_unicode_ci NOT NULL,
  `ques_addedby` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`qid`),
  KEY `ques_tempid` (`ques_tempid`),
  FULLTEXT KEY `ques_fulltext` (`ques_category`,`ques_question`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `recommendas`
--

CREATE TABLE IF NOT EXISTS `recommendas` (
  `raid` int(16) NOT NULL AUTO_INCREMENT,
  `reca_rqid` int(16) NOT NULL,
  `reca_answer` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`raid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `recommendqs`
--

CREATE TABLE IF NOT EXISTS `recommendqs` (
  `rqid` int(16) NOT NULL AUTO_INCREMENT,
  `recq_category` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `recq_question` varchar(512) COLLATE utf8_unicode_ci NOT NULL,
  `recq_addedby` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `recq_source` varchar(512) COLLATE utf8_unicode_ci NOT NULL,
  `recq_lastshow` int(11) NOT NULL,
  UNIQUE KEY `rqid` (`rqid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Triggers `recommendqs`
--
DROP TRIGGER IF EXISTS `delete_recomq`;
DELIMITER //
CREATE TRIGGER `delete_recomq` AFTER DELETE ON `recommendqs`
 FOR EACH ROW BEGIN
  DELETE FROM recommendas WHERE reca_rqid = OLD.rqid;
END
//
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE IF NOT EXISTS `reports` (
  `rid` int(16) NOT NULL AUTO_INCREMENT,
  `repo_qid` int(16) NOT NULL,
  `repo_comment` varchar(512) COLLATE utf8_unicode_ci NOT NULL,
  `repo_user` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `repo_lastshow` int(11) NOT NULL,
  PRIMARY KEY (`rid`),
  KEY `repo_lastshow` (`repo_lastshow`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `uid` int(16) NOT NULL AUTO_INCREMENT,
  `user_nick` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `user_points_season` int(16) NOT NULL,
  `user_points_total` int(16) NOT NULL,
  `user_time` double NOT NULL,
  `user_inarow` int(16) NOT NULL,
  `user_mana` int(16) NOT NULL,
  `user_class` int(16) NOT NULL,
  `user_lastactive` int(16) NOT NULL,
  `user_customclass` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `user_lastactive_chan` varchar(200) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `user_nick` (`user_nick`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

