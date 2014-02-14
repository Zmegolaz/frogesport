Version 1.4 -> 1.5

ALTER TABLE `questions` MODIFY COLUMN `ques_tempid` DECIMAL(16,5) NOT NULL ;
ALTER TABLE `users` ADD `user_lastactive_chan` VARCHAR( 200 ) NOT NULL ;
ALTER TABLE `answers` ADD `answ_prefer` BOOLEAN NOT NULL ;
ALTER TABLE `recommendas` ADD `reca_prefer` BOOLEAN NOT NULL ;

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
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;
