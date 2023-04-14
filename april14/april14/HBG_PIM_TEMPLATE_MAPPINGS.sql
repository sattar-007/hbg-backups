--------------------------------------------------------
--  DDL for Table HBG_PIM_TEMPLATE_MAPPINGS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_PIM_TEMPLATE_MAPPINGS" 
   (	"LOAD_SEQUENCE" NUMBER, 
	"ORGANIZATION_CODE" VARCHAR2(20 BYTE), 
	"TEMPLATE_NAME" VARCHAR2(1000 BYTE), 
	"ITEM_CLASS_NAME" VARCHAR2(100 BYTE), 
	"OWNER_CODE" VARCHAR2(150 BYTE), 
	"OWNER_NAME" VARCHAR2(150 BYTE), 
	"DIGITAL_CONTENT_FLAG" CHAR(1 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;