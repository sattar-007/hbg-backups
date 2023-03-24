--------------------------------------------------------
--  DDL for Table HBG_DIST_RIGHTS_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_DIST_RIGHTS_EXT" 
   (	"DISTRIBUTION_RIGHT_ID" NUMBER, 
	"OWNER" VARCHAR2(25 BYTE), 
	"REPORTING_GROUP" VARCHAR2(25 BYTE), 
	"CATEGORY_1" VARCHAR2(25 BYTE), 
	"CATEGORY_2" VARCHAR2(25 BYTE), 
	"FORMAT" VARCHAR2(25 BYTE), 
	"SUB_FORMAT" VARCHAR2(25 BYTE), 
	"EDITION" NUMBER, 
	"ITEM_NUMBER" VARCHAR2(255 BYTE), 
	"FROM_PUB_DATE" DATE, 
	"TO_PUB_DATE" DATE, 
	"COUNTRY_GROUP_ID" NUMBER, 
	"COUNTRY_ID" NUMBER, 
	"OUTCOME" VARCHAR2(255 BYTE), 
	"COMMENTS" VARCHAR2(2000 BYTE), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"PRECEDENCE_LEVEL" NUMBER, 
	"RULES_GROUP" VARCHAR2(255 BYTE), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"ACCOUNT_TYPE" VARCHAR2(255 BYTE), 
	"DEFAULT_ACCOUNT_TYPE" VARCHAR2(255 BYTE), 
	"CUST_ACCOUNT_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_DIST_RIGHTS_EXT" TO "RO_HBG_INTEGRATION";
