--------------------------------------------------------
--  DDL for Table FND_PROFILE_OPTIONS_VL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."FND_PROFILE_OPTIONS_VL" 
   (	"ROW_ID" ROWID, 
	"MODULE_ID" VARCHAR2(128 BYTE), 
	"APPLICATION_ID" NUMBER, 
	"PROFILE_OPTION_ID" NUMBER, 
	"PROFILE_OPTION_NAME" VARCHAR2(320 BYTE), 
	"USER_PROFILE_OPTION_NAME" VARCHAR2(960 BYTE), 
	"HIERARCHY_NAME" VARCHAR2(120 BYTE), 
	"USER_ENABLED_FLAG" VARCHAR2(4 BYTE), 
	"USER_UPDATEABLE_FLAG" VARCHAR2(4 BYTE), 
	"SQL_VALIDATION" VARCHAR2(4000 BYTE), 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
	"DESCRIPTION" VARCHAR2(960 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."FND_PROFILE_OPTIONS_VL" TO "RO_HBG_INTEGRATION";
