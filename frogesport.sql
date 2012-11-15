
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `frogesport`
--

-- --------------------------------------------------------

--
-- Table structure for table `answers`
--

CREATE TABLE IF NOT EXISTS `answers` (
  `aid` int(16) NOT NULL AUTO_INCREMENT,
  `answ_question` int(16) NOT NULL,
  `answ_answer` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`aid`),
  KEY `answ_question` (`answ_question`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=52672 ;

-- --------------------------------------------------------

--
-- Table structure for table `classes`
--

CREATE TABLE IF NOT EXISTS `classes` (
  `cid` int(16) NOT NULL AUTO_INCREMENT,
  `clas_points` int(16) NOT NULL,
  `clas_name` varchar(128) CHARACTER SET latin1 NOT NULL,
  `clas_maxmana` int(16) NOT NULL,
  `clas_comment` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `clas_points` (`clas_points`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=12 ;

-- --------------------------------------------------------

--
-- Table structure for table `prizes`
--

CREATE TABLE IF NOT EXISTS `prizes` (
  `pid` int(16) NOT NULL AUTO_INCREMENT,
  `priz_inarow` varchar(16) CHARACTER SET latin1 NOT NULL,
  `priz_prize` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`pid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=48 ;

-- --------------------------------------------------------

--
-- Table structure for table `questions`
--

CREATE TABLE IF NOT EXISTS `questions` (
  `qid` int(16) NOT NULL AUTO_INCREMENT,
  `ques_category` varchar(256) CHARACTER SET latin1 NOT NULL,
  `ques_question` varchar(512) CHARACTER SET latin1 NOT NULL,
  `ques_tempid` int(16) DEFAULT NULL,
  PRIMARY KEY (`qid`),
  KEY `ques_tempid` (`ques_tempid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=22147 ;

-- --------------------------------------------------------

--
-- Table structure for table `recommendas`
--

CREATE TABLE IF NOT EXISTS `recommendas` (
  `raid` int(16) NOT NULL AUTO_INCREMENT,
  `reca_rqid` int(16) NOT NULL,
  `reca_answer` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`raid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `recommendqs`
--

CREATE TABLE IF NOT EXISTS `recommendqs` (
  `rqid` int(16) NOT NULL AUTO_INCREMENT,
  `recq_category` varchar(256) CHARACTER SET latin1 NOT NULL,
  `recq_question` varchar(512) CHARACTER SET latin1 NOT NULL,
  `recq_user` varchar(256) CHARACTER SET latin1 NOT NULL,
  UNIQUE KEY `rqid` (`rqid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

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
  `repo_comment` varchar(512) CHARACTER SET latin1 NOT NULL,
  `repo_user` varchar(128) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1814 ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `uid` int(16) NOT NULL AUTO_INCREMENT,
  `user_nick` varchar(256) CHARACTER SET latin1 NOT NULL,
  `user_points_season` int(16) NOT NULL,
  `user_points_total` int(16) NOT NULL,
  `user_time` double NOT NULL,
  `user_inarow` int(16) NOT NULL,
  `user_mana` int(16) NOT NULL,
  `user_class` int(16) NOT NULL,
  `user_lastactive` int(16) NOT NULL,
  `user_customclass` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `user_nick` (`user_nick`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1708 ;

-- --------------------------------------------------------

--
-- Table structure for table `users_last_season`
--

CREATE TABLE IF NOT EXISTS `users_last_season` (
  `uid` int(16) NOT NULL AUTO_INCREMENT,
  `user_nick` varchar(256) CHARACTER SET latin1 NOT NULL,
  `user_points_season` int(16) NOT NULL,
  `user_points_total` int(16) NOT NULL,
  `user_time` double NOT NULL,
  `user_inarow` int(16) NOT NULL,
  `user_mana` int(16) NOT NULL,
  `user_class` int(16) NOT NULL,
  `user_lastactive` int(16) NOT NULL,
  `user_customclass` varchar(256) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `user_nick` (`user_nick`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1555 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
