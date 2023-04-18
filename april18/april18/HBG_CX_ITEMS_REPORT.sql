--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_REPORT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_REPORT" 
   (	"ISBN" VARCHAR2(100 BYTE), 
	"ISBN10" VARCHAR2(100 BYTE), 
	"WORK_ISBN" VARCHAR2(100 BYTE), 
	"WORK_TITLE" VARCHAR2(2000 BYTE), 
	"WORK_SUB_TITLE" VARCHAR2(2000 BYTE), 
	"OWNER_CODE" VARCHAR2(2 BYTE), 
	"OWNER" VARCHAR2(200 BYTE), 
	"REPORTING_GROUP_CODE" NUMBER, 
	"REPORTING_GROUP_CODE_DESC" VARCHAR2(200 BYTE), 
	"PUBLISHER_CODE" VARCHAR2(5 BYTE), 
	"PUBLISHER" VARCHAR2(200 BYTE), 
	"IMPRINT_CODE" VARCHAR2(5 BYTE), 
	"IMPRINT" VARCHAR2(100 BYTE), 
	"EXTERNAL_PUBLISHER_CODE" VARCHAR2(5 BYTE), 
	"EXTERNAL_PUBLISHER" VARCHAR2(200 BYTE), 
	"EXTERNAL_IMPRINT_CODE" VARCHAR2(5 BYTE), 
	"EXTERNAL_IMPRINT" VARCHAR2(200 BYTE), 
	"TITLE" VARCHAR2(2000 BYTE), 
	"SUB_TITLE" VARCHAR2(2000 BYTE), 
	"EDITION" VARCHAR2(100 BYTE), 
	"PUB_STATUS" VARCHAR2(100 BYTE), 
	"MEDIA" VARCHAR2(100 BYTE), 
	"FORMAT_CODE" VARCHAR2(2 BYTE), 
	"FORMAT" VARCHAR2(100 BYTE), 
	"SUB_FORMAT_CODE" VARCHAR2(2 BYTE), 
	"SUB_FORMAT" VARCHAR2(100 BYTE), 
	"SERIES" VARCHAR2(200 BYTE), 
	"SERIES_NUMBER" VARCHAR2(30 BYTE), 
	"BY_LINE" VARCHAR2(1000 BYTE), 
	"PUBLICATION_DATE" VARCHAR2(100 BYTE), 
	"KEYWORD" VARCHAR2(1000 BYTE), 
	"BOOK_DESCRIPTION" CLOB, 
	"RANK_VAL" NUMBER, 
	"PRIMARY_FLAG" VARCHAR2(1 BYTE), 
	"STATUS" VARCHAR2(500 BYTE), 
	"INSTANCEID" NUMBER, 
	"COMMENTS" VARCHAR2(4000 BYTE), 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	"CX_ACTIVE" VARCHAR2(20 BYTE), 
	"HIDE_FROM_ONIX" VARCHAR2(20 BYTE), 
	"CUSTOMER_SPECIFIC_CODE" VARCHAR2(20 BYTE), 
	"CUSTOMER_SPECIFIC_DESC" VARCHAR2(4000 BYTE), 
	"COLUMN1" VARCHAR2(20 BYTE), 
	"HBG_PROCESS_ID" NUMBER(20,0)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("BOOK_DESCRIPTION") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_REPORT" TO "RO_HBG_INTEGRATION";
