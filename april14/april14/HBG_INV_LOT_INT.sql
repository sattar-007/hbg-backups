--------------------------------------------------------
--  DDL for Table HBG_INV_LOT_INT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_INV_LOT_INT" 
   (	"ITEM_NUMBER" VARCHAR2(100 BYTE), 
	"LOT_NUMBER" VARCHAR2(100 BYTE), 
	"USD_PRICE" NUMBER, 
	"CAD_PRICE" NUMBER, 
	"LOT_STATUS" VARCHAR2(100 BYTE), 
	"INVENTORY_TYPE" VARCHAR2(100 BYTE), 
	"ACTIVE_FLAG" VARCHAR2(10 BYTE), 
	"PROCESS_STATUS" VARCHAR2(100 BYTE), 
	"PROCESS_MSG" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"ORGANIZATION_CODE" VARCHAR2(20 BYTE), 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_INV_LOT_INT" TO "RO_HBG_INTEGRATION";
