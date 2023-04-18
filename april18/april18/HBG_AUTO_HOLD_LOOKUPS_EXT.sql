--------------------------------------------------------
--  DDL for Table HBG_AUTO_HOLD_LOOKUPS_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_AUTO_HOLD_LOOKUPS_EXT" 
   (	"LOOKUP_TYPE" VARCHAR2(255 BYTE), 
	"LOOKUP_CODE" VARCHAR2(255 BYTE), 
	"MEANING" VARCHAR2(255 BYTE), 
	"DESCRIPTION" VARCHAR2(255 BYTE), 
	"ENABLED_FLAG" VARCHAR2(255 BYTE), 
	"DISPLAY_SEQUENCE" NUMBER, 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"TAG" VARCHAR2(255 BYTE), 
	"STATUS" VARCHAR2(5 BYTE), 
	"STATUS_MESSAGE" BLOB, 
	"OIC_RUN_ID" NUMBER
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
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_AUTO_HOLD_LOOKUPS_EXT" TO "RO_HBG_INTEGRATION";