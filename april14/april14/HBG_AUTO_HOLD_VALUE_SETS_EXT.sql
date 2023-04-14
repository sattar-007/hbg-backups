--------------------------------------------------------
--  DDL for Table HBG_AUTO_HOLD_VALUE_SETS_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_AUTO_HOLD_VALUE_SETS_EXT" 
   (	"VALUE_SET_NAME" VARCHAR2(200 BYTE), 
	"FLEX_VALUE" VARCHAR2(200 BYTE), 
	"DESCRIPTION" VARCHAR2(200 BYTE), 
	"ENABLED_FLAG" VARCHAR2(200 BYTE), 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"OIC_RUN_ID" NUMBER, 
	"STATUS" VARCHAR2(200 BYTE), 
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
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_AUTO_HOLD_VALUE_SETS_EXT" TO "RO_HBG_INTEGRATION";
