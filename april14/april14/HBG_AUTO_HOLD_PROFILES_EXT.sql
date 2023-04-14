--------------------------------------------------------
--  DDL for Table HBG_AUTO_HOLD_PROFILES_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_AUTO_HOLD_PROFILES_EXT" 
   (	"PROFILE_OPTION_ID" NUMBER, 
	"PROFILE_OPTION_NAME" VARCHAR2(100 BYTE), 
	"USER_PROFILE_OPTION_NAME" VARCHAR2(255 BYTE), 
	"DESCRIPTION" VARCHAR2(255 BYTE), 
	"LEVEL_NAME" VARCHAR2(100 BYTE), 
	"LEVEL_VALUE" VARCHAR2(1000 BYTE), 
	"PROFILE_OPTION_VALUE" VARCHAR2(1000 BYTE), 
	"CREATED_BY" VARCHAR2(64 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(64 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"OIC_RUN_ID" NUMBER, 
	"STATUS" VARCHAR2(100 BYTE), 
	"STATUS_MESSAGE" CLOB
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("STATUS_MESSAGE") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_AUTO_HOLD_PROFILES_EXT" TO "RO_HBG_INTEGRATION";
