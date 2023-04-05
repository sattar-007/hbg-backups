--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_CATEGORIES
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_CATEGORIES" 
   (	"PRODUCT_ID" VARCHAR2(50 BYTE), 
	"CATEGORY_ID" VARCHAR2(50 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATE_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_CATEGORIES" TO "RO_HBG_INTEGRATION";
