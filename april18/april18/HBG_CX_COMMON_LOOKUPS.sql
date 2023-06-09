--------------------------------------------------------
--  DDL for Table HBG_CX_COMMON_LOOKUPS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_COMMON_LOOKUPS" 
   (	"LOOKUP_TYPE" VARCHAR2(120 BYTE), 
	"LOOKUP_CODE" VARCHAR2(120 BYTE), 
	"MEANING" VARCHAR2(320 BYTE), 
	"DESCRIPTION" VARCHAR2(960 BYTE), 
	"ENABLED_FLAG" VARCHAR2(4 BYTE), 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
	"DISPLAY_SEQUENCE" NUMBER, 
	"CHANGE_SINCE_LAST_REFRESH" VARCHAR2(4 BYTE), 
	"INS_USER" VARCHAR2(256 BYTE), 
	"INS_TIMESTAMP" DATE, 
	"LAST_UPDATE_USER" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_TIMESTAMP" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
