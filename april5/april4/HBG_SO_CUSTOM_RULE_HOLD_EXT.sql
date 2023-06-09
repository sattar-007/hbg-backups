--------------------------------------------------------
--  DDL for Table HBG_SO_CUSTOM_RULE_HOLD_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_SO_CUSTOM_RULE_HOLD_EXT" 
   (	"SOURCE_ORDER_SYSTEM" VARCHAR2(255 BYTE), 
	"SOURCE_ORDER_ID" VARCHAR2(255 BYTE), 
	"SOURCE_LINE_ID" VARCHAR2(255 BYTE), 
	"SOURCEHOLDCODE" VARCHAR2(200 BYTE), 
	"HOLDCOMMENTS" VARCHAR2(2000 BYTE), 
	"HOLDRELEASEREASONCODE" VARCHAR2(200 BYTE), 
	"HOLDRELEASECOMMENTS" VARCHAR2(2000 BYTE), 
	"HOLDFLAG" VARCHAR2(20 BYTE), 
	"ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"ORDER_NUMBER" VARCHAR2(200 BYTE), 
	"OIC_RUN_ID" NUMBER, 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"STATUS_MESSAGE" VARCHAR2(255 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_SO_CUSTOM_RULE_HOLD_EXT" TO "RO_HBG_INTEGRATION";
