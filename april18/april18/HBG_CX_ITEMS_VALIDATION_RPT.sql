--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_VALIDATION_RPT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_VALIDATION_RPT" 
   (	"SKU_ID" VARCHAR2(30 BYTE), 
	"DISPLAY_NAME" VARCHAR2(4000 BYTE), 
	"PRODUCT_ID" VARCHAR2(30 BYTE), 
	"TYPE" VARCHAR2(30 BYTE), 
	"ACTIVE" VARCHAR2(5 BYTE), 
	"PUB_STATUS" VARCHAR2(30 BYTE), 
	"EXTERNAL_IMPRINT" VARCHAR2(500 BYTE), 
	"EDITION" VARCHAR2(500 BYTE), 
	"DISCOUNTABLE" VARCHAR2(5 BYTE), 
	"AUTHOR_LIST" VARCHAR2(1000 BYTE), 
	"AUTHOR_NAME" VARCHAR2(1000 BYTE), 
	"BOOK_TYPE" VARCHAR2(200 BYTE), 
	"IMPRINT" VARCHAR2(200 BYTE), 
	"LONG_DESCRIPTION" CLOB, 
	"OWNER" VARCHAR2(200 BYTE), 
	"REPORTING_GROUP" VARCHAR2(200 BYTE), 
	"PRIMARY_PRODUCT" VARCHAR2(5 BYTE), 
	"PUBLICATION_DATE" VARCHAR2(50 BYTE), 
	"PUBLISHER" VARCHAR2(200 BYTE), 
	"SERIES" VARCHAR2(200 BYTE), 
	"SERIES_NUMBER" VARCHAR2(30 BYTE), 
	"SUB_PRODUCT" VARCHAR2(200 BYTE), 
	"SUB_TITLE" VARCHAR2(4000 BYTE), 
	"INSTANCEID" NUMBER, 
	"CUSTOMER_SPECIFIC_CODE" VARCHAR2(20 BYTE), 
	"CUSTOMER_SPECIFIC_DESC" VARCHAR2(4000 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("LONG_DESCRIPTION") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_VALIDATION_RPT" TO "RO_HBG_INTEGRATION";
