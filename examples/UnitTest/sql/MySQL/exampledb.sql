/*
 Source Server Type    : MySQL
 Source Server Version : 50710
 Source Schema         : eql_test

 Target Server Type    : MySQL
 Target Server Version : 50710
 File Encoding         : 65001

 Date: 18/08/2020 15:07:13
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for AppInfo
-- ----------------------------
DROP TABLE IF EXISTS `AppInfo`;
CREATE TABLE `AppInfo`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `desc` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `available` bit(1) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of AppInfo
-- ----------------------------
INSERT INTO `AppInfo` VALUES (1, 'Vitis', 'test1', b'1');
INSERT INTO `AppInfo` VALUES (2, 'no name', '', b'0');

-- ----------------------------
-- Table structure for Car
-- ----------------------------
DROP TABLE IF EXISTS `Car`;
CREATE TABLE `Car`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0',
  `uid` int(11) NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of Car
-- ----------------------------
INSERT INTO `Car` VALUES (1, 'BMW', 2);
INSERT INTO `Car` VALUES (2, 'BENZ', 1);
INSERT INTO `Car` VALUES (3, 'QQ', 1);
INSERT INTO `Car` VALUES (4, 'LEXS', 2);
INSERT INTO `Car` VALUES (5, NULL, NULL);
INSERT INTO `Car` VALUES (6, '', NULL);

-- ----------------------------
-- Table structure for IDCard
-- ----------------------------
DROP TABLE IF EXISTS `IDCard`;
CREATE TABLE `IDCard`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `desc` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '0',
  `uid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of IDCard
-- ----------------------------
INSERT INTO `IDCard` VALUES (1, 'China', 1);
INSERT INTO `IDCard` VALUES (2, 'US', 2);

-- ----------------------------
-- Table structure for LoginInfo
-- ----------------------------
DROP TABLE IF EXISTS `LoginInfo`;
CREATE TABLE `LoginInfo`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL DEFAULT 0,
  `appid` int(11) NOT NULL DEFAULT 0,
  `create_time` int(11) NOT NULL DEFAULT 0,
  `update_time` int(11) NOT NULL DEFAULT 0,
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of LoginInfo
-- ----------------------------
INSERT INTO `LoginInfo` VALUES (1, 2, 1, 1539155655, 1539155692, 'null');
INSERT INTO `LoginInfo` VALUES (2, 1, 2, 1539156242, 1539156252, NULL);
INSERT INTO `LoginInfo` VALUES (3, 1, 1, 1540462504, 1540462504, NULL);
INSERT INTO `LoginInfo` VALUES (4, 4, 1, 1540462505, 1540462506, NULL);
INSERT INTO `LoginInfo` VALUES (5, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (6, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (7, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (8, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (9, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (10, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (11, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (12, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (13, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (14, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (15, 0, 0, 0, 0, 'new location');
INSERT INTO `LoginInfo` VALUES (16, 0, 0, 0, 0, 'new location');

-- ----------------------------
-- Table structure for UserApp
-- ----------------------------
DROP TABLE IF EXISTS `UserApp`;
CREATE TABLE `UserApp`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL DEFAULT 0,
  `appid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of UserApp
-- ----------------------------
INSERT INTO `UserApp` VALUES (1, 1, 2);
INSERT INTO `UserApp` VALUES (2, 1, 1);
INSERT INTO `UserApp` VALUES (3, 2, 1);
INSERT INTO `UserApp` VALUES (4, 2, 2);
INSERT INTO `UserApp` VALUES (5, 4, 1);

-- ----------------------------
-- Table structure for UserInfo
-- ----------------------------
DROP TABLE IF EXISTS `UserInfo`;
CREATE TABLE `UserInfo`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '0',
  `age` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 147 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of UserInfo
-- ----------------------------
INSERT INTO `UserInfo` VALUES (1, 'Ryoes', 100);
INSERT INTO `UserInfo` VALUES (2, 'Jeck', 5);
INSERT INTO `UserInfo` VALUES (4, 'Lily', 77);
INSERT INTO `UserInfo` VALUES (43, 'Jame\'s HaDeng', 30);
INSERT INTO `UserInfo` VALUES (91, 'Siri', 10);
INSERT INTO `UserInfo` VALUES (116, 'gxc', 100);
INSERT INTO `UserInfo` VALUES (128, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (129, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (130, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (131, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (132, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (133, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (135, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (136, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (140, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (141, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (142, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (143, 'Jons', 2355);
INSERT INTO `UserInfo` VALUES (145, 'momomo', 666);
INSERT INTO `UserInfo` VALUES (146, 'Jons', 2355);

SET FOREIGN_KEY_CHECKS = 1;

