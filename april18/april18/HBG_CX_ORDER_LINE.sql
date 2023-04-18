--------------------------------------------------------
--  DDL for Table HBG_CX_ORDER_LINE
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ORDER_LINE" 
   (	"CATALOG_REF_ID" VARCHAR2(20 BYTE), 
	"QUANTITY" VARCHAR2(20 BYTE), 
	"PRICE" VARCHAR2(20 BYTE), 
	"LINE_NUMBER" NUMBER, 
	"ORDER_HEADER_SOURCE_ID" VARCHAR2(20 BYTE), 
	"LINE_ID" VARCHAR2(50 BYTE), 
	"CANCELLATION_DATE" VARCHAR2(50 BYTE), 
	"CREATION_DATE" DATE, 
	"INTEGRATION_STATUS_ERP" VARCHAR2(50 BYTE), 
	"IMPORT_COMMENTS" VARCHAR2(4000 BYTE), 
	"TAX_AMOUNT" NUMBER, 
	"UNIT_PRICE" VARCHAR2(20 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ORDER_LINE" TO "RO_HBG_INTEGRATION";
