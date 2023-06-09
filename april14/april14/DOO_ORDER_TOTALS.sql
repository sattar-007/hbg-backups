--------------------------------------------------------
--  DDL for Table DOO_ORDER_TOTALS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."DOO_ORDER_TOTALS" 
   (	"ORDER_TOTAL_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"TOTAL_GROUP" VARCHAR2(960 BYTE), 
	"CURRENCY_CODE" VARCHAR2(60 BYTE), 
	"ESTIMATED_FLAG" VARCHAR2(4 BYTE), 
	"PRIMARY_FLAG" VARCHAR2(4 BYTE), 
	"TOTAL_AMOUNT" NUMBER, 
	"TOTAL_CODE" VARCHAR2(120 BYTE), 
	"DISPLAY_NAME" VARCHAR2(1020 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"OBJECT_VERSION_NUMBER" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."DOO_ORDER_TOTALS" TO "RO_HBG_INTEGRATION";
