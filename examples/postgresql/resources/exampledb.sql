/*
 Source Server Type    : PostgreSQL
 Source Server Version : 100005
 Source Catalog        : exampledb
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 100005
 File Encoding         : 65001

 Date: 18/09/2019 15:01:14
*/


-- ----------------------------
-- Sequence structure for appinfo_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "appinfo_id_seq";
CREATE SEQUENCE "appinfo_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for car_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "car_id_seq";
CREATE SEQUENCE "car_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for idcar_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "idcar_id_seq";
CREATE SEQUENCE "idcar_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for idcard_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "idcard_id_seq";
CREATE SEQUENCE "idcard_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for logininfo_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "logininfo_id_seq";
CREATE SEQUENCE "logininfo_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for userapp_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "userapp_id_seq";
CREATE SEQUENCE "userapp_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for userinfo_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "userinfo_id_seq";
CREATE SEQUENCE "userinfo_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Table structure for appinfo
-- ----------------------------
DROP TABLE IF EXISTS "appinfo";
CREATE TABLE "appinfo" (
  "id" int4 NOT NULL DEFAULT nextval('appinfo_id_seq'::regclass),
  "name" varchar(200) COLLATE "pg_catalog"."default",
  "desc" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of appinfo
-- ----------------------------
BEGIN;
INSERT INTO "appinfo" VALUES (1, 'Vitis', 'it''s a IM service');
INSERT INTO "appinfo" VALUES (2, '葡萄乐园', '葡萄商城app');
COMMIT;

-- ----------------------------
-- Table structure for car
-- ----------------------------
DROP TABLE IF EXISTS "car";
CREATE TABLE "car" (
  "id" int4 NOT NULL DEFAULT nextval('car_id_seq'::regclass),
  "uid" int4,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of car
-- ----------------------------
BEGIN;
INSERT INTO "car" VALUES (1, 2, 'BMW');
INSERT INTO "car" VALUES (2, 1, 'BENZ');
INSERT INTO "car" VALUES (3, 1, 'QQ');
INSERT INTO "car" VALUES (4, 2, 'LEXS');
COMMIT;

-- ----------------------------
-- Table structure for idcard
-- ----------------------------
DROP TABLE IF EXISTS "idcard";
CREATE TABLE "idcard" (
  "id" int4 NOT NULL DEFAULT nextval('idcard_id_seq'::regclass),
  "uid" int4,
  "desc" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of idcard
-- ----------------------------
BEGIN;
INSERT INTO "idcard" VALUES (1, 1, 'China');
INSERT INTO "idcard" VALUES (2, 2, 'US');
COMMIT;

-- ----------------------------
-- Table structure for logininfo
-- ----------------------------
DROP TABLE IF EXISTS "logininfo";
CREATE TABLE "logininfo" (
  "id" int4 NOT NULL DEFAULT nextval('logininfo_id_seq'::regclass),
  "uid" int4,
  "appid" int4,
  "create_time" int4,
  "update_time" int4
)
;

-- ----------------------------
-- Records of logininfo
-- ----------------------------
BEGIN;
INSERT INTO "logininfo" VALUES (1, 2, 2, 1539155655, 1539155658);
INSERT INTO "logininfo" VALUES (2, 1, 2, 1539156242, 1539156252);
INSERT INTO "logininfo" VALUES (3, 1, 1, 1540462504, 1540462504);
INSERT INTO "logininfo" VALUES (4, 4, 1, 1540462505, 1540462506);
COMMIT;

-- ----------------------------
-- Table structure for userapp
-- ----------------------------
DROP TABLE IF EXISTS "userapp";
CREATE TABLE "userapp" (
  "id" int4 NOT NULL DEFAULT nextval('userapp_id_seq'::regclass),
  "uid" int4,
  "appid" int4
)
;

-- ----------------------------
-- Records of userapp
-- ----------------------------
BEGIN;
INSERT INTO "userapp" VALUES (1, 1, 2);
INSERT INTO "userapp" VALUES (2, 1, 1);
INSERT INTO "userapp" VALUES (3, 2, 1);
INSERT INTO "userapp" VALUES (4, 2, 2);
INSERT INTO "userapp" VALUES (5, 4, 1);
COMMIT;

-- ----------------------------
-- Table structure for userinfo
-- ----------------------------
DROP TABLE IF EXISTS "userinfo";
CREATE TABLE "userinfo" (
  "id" int4 NOT NULL DEFAULT nextval('userinfo_id_seq'::regclass),
  "nickname" varchar(200) COLLATE "pg_catalog"."default",
  "age" int4
)
;

-- ----------------------------
-- Records of userinfo
-- ----------------------------
BEGIN;
INSERT INTO "userinfo" VALUES (2, 'Jeck', 5);
INSERT INTO "userinfo" VALUES (4, 'Lily', 30);
INSERT INTO "userinfo" VALUES (107, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (75, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (110, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (113, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (116, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (85, 'Ha''Deng', 30);
INSERT INTO "userinfo" VALUES (119, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (1, 'Jons', 3);
INSERT INTO "userinfo" VALUES (50, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (52, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (54, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (56, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (58, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (60, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (62, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (64, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (66, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (69, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (72, 'Jons', 2355);
INSERT INTO "userinfo" VALUES (104, 'Jons', 2355);
COMMIT;

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
SELECT setval('"appinfo_id_seq"', 3, true);
SELECT setval('"car_id_seq"', 5, true);
SELECT setval('"idcar_id_seq"', 2, false);
SELECT setval('"idcard_id_seq"', 3, true);
SELECT setval('"logininfo_id_seq"', 5, true);
SELECT setval('"userapp_id_seq"', 6, true);
SELECT setval('"userinfo_id_seq"', 120, true);

-- ----------------------------
-- Primary Key structure for table appinfo
-- ----------------------------
ALTER TABLE "appinfo" ADD CONSTRAINT "appinfo_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table car
-- ----------------------------
ALTER TABLE "car" ADD CONSTRAINT "car_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table idcard
-- ----------------------------
ALTER TABLE "idcard" ADD CONSTRAINT "idcard_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table logininfo
-- ----------------------------
ALTER TABLE "logininfo" ADD CONSTRAINT "logininfo_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table userapp
-- ----------------------------
ALTER TABLE "userapp" ADD CONSTRAINT "userapp_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table userinfo
-- ----------------------------
ALTER TABLE "userinfo" ADD CONSTRAINT "userinfo_pkey" PRIMARY KEY ("id");
