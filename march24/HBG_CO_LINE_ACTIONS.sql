--------------------------------------------------------
--  DDL for Table HBG_CO_LINE_ACTIONS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CO_LINE_ACTIONS" 
   (	"LINE_ACTION_ID" NUMBER, 
	"RULE_LINE_ID" NUMBER, 
	"TEMPLATE_ID" NUMBER, 
	"HOLD_FLAG" VARCHAR2(5 BYTE), 
	"HOLD_LEVEL" VARCHAR2(100 BYTE), 
	"HOLD_NAME" VARCHAR2(100 BYTE), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"TEMPLATE_LEVEL" VARCHAR2(200 BYTE), 
	"ENTERED_DATE" DATE, 
	"UPDATED_DATE" DATE, 
	"UPDATED_BY" VARCHAR2(200 BYTE), 
	"ENTERED_BY" VARCHAR2(200 BYTE), 
	"TEMPLATE_NAME" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;