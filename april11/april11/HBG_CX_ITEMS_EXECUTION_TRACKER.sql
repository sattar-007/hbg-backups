--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_EXECUTION_TRACKER
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_EXECUTION_TRACKER" 
   (	"INSTANCEID" NUMBER, 
	"PRODUCT_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"PRODUCT_REC" NUMBER, 
	"SKU_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"SKU_REC" NUMBER, 
	"COL_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"COL_REC" NUMBER, 
	"CNTB_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"CNTB_REC" NUMBER, 
	"INV_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"INV_REC" NUMBER, 
	"PRICE_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"PRICE_REC" NUMBER, 
	"REPORT_EXEC" INTERVAL DAY (2) TO SECOND (6), 
	"REQUEST" CLOB, 
	"SKU_API" INTERVAL DAY (2) TO SECOND (6), 
	"SKU_COMPARE" INTERVAL DAY (2) TO SECOND (6), 
	"SKU_VALIDATION" INTERVAL DAY (2) TO SECOND (6), 
	"CREATION_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("REQUEST") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_EXECUTION_TRACKER" TO "RO_HBG_INTEGRATION";
