--------------------------------------------------------
--  DDL for Table DOO_LINES_ALL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."DOO_LINES_ALL" 
   (	"HEADER_ID" NUMBER, 
	"LINE_ID" NUMBER, 
	"LINE_NUMBER" NUMBER, 
	"STATUS_CODE" VARCHAR2(120 BYTE), 
	"OWNER_ID" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"SOURCE_LINE_ID" VARCHAR2(200 BYTE), 
	"SOURCE_LINE_NUMBER" VARCHAR2(400 BYTE), 
	"SOURCE_ORDER_ID" VARCHAR2(200 BYTE), 
	"SOURCE_ORDER_NUMBER" VARCHAR2(200 BYTE), 
	"SOURCE_ORDER_SYSTEM" VARCHAR2(120 BYTE), 
	"SOURCE_SCHEDULE_ID" VARCHAR2(200 BYTE), 
	"SOURCE_SCHEDULE_NUMBER" VARCHAR2(200 BYTE), 
	"SOURCE_REVISION_NUMBER" NUMBER, 
	"ITEM_TYPE_CODE" VARCHAR2(120 BYTE), 
	"ORDERED_QTY" NUMBER, 
	"CANCELED_QTY" NUMBER, 
	"ORDERED_UOM" VARCHAR2(12 BYTE), 
	"SOURCE_ORG_ID" NUMBER, 
	"ORG_ID" NUMBER, 
	"ACTUAL_SHIP_DATE" DATE, 
	"SCHEDULE_SHIP_DATE" DATE, 
	"RMA_DELIVERED_QTY" NUMBER, 
	"EXTENDED_AMOUNT" NUMBER, 
	"FULFILLED_QTY" NUMBER, 
	"FULFILLMENT_DATE" DATE, 
	"LINE_TYPE_CODE" VARCHAR2(120 BYTE), 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"OPEN_FLAG" VARCHAR2(4 BYTE), 
	"CANCELED_FLAG" VARCHAR2(4 BYTE), 
	"INVENTORY_ITEM_ID" NUMBER, 
	"COMP_SEQ_PATH" VARCHAR2(4000 BYTE), 
	"PARENT_LINE_ID" NUMBER, 
	"ORIG_SYS_DOCUMENT_REF" VARCHAR2(200 BYTE), 
	"ORIG_SYS_DOCUMENT_LINE_REF" VARCHAR2(200 BYTE), 
	"ROOT_PARENT_LINE_ID" NUMBER, 
	"SHIPPED_QTY" NUMBER, 
	"UNIT_LIST_PRICE" NUMBER, 
	"UNIT_SELLING_PRICE" NUMBER, 
	"DELTA_TYPE" NUMBER, 
	"REFERENCE_LINE_ID" NUMBER, 
	"ON_HOLD" VARCHAR2(4 BYTE), 
	"INVENTORY_ORGANIZATION_ID" NUMBER, 
	"CATEGORY_CODE" VARCHAR2(120 BYTE), 
	"TRANSFORM_FROM_LINE_ID" NUMBER, 
	"ITEM_SUB_TYPE_CODE" VARCHAR2(120 BYTE), 
	"QUANTITY_PER_MODEL" NUMBER, 
	"MODIFIED_FLAG" VARCHAR2(4 BYTE), 
	"DISPLAY_LINE_NUMBER" VARCHAR2(400 BYTE), 
	"CREATED_IN_RELEASE" VARCHAR2(60 BYTE), 
	"DIST_TITLE_HOLD_FLAG" VARCHAR2(25 BYTE), 
	"DIST_TITLE_HOLD_COMMENTS" VARCHAR2(1000 BYTE), 
	"SF_MAPPING" VARCHAR2(255 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."DOO_LINES_ALL" TO "RO_HBG_INTEGRATION";
