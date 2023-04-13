--------------------------------------------------------
--  DDL for Table HBG_STERLING_COMMENT_STG
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_STERLING_COMMENT_STG" 
   (	"STAGE_ACCOUNT_NO" VARCHAR2(8 BYTE), 
	"PRESTAGE_STATUS" VARCHAR2(1 BYTE), 
	"PURCHASE_ORDER_NO" VARCHAR2(50 BYTE), 
	"COMMENT_TEXT1" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT2" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT3" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT4" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT5" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT6" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT7" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT8" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT9" VARCHAR2(200 BYTE), 
	"COMMENT_TEXT10" VARCHAR2(200 BYTE), 
	"ASD_UID" NUMBER, 
	"GIS_HEADER_UID" NUMBER(10,0), 
	"SBI_UUID" VARCHAR2(50 BYTE), 
	"GIS_ID" NUMBER, 
	"HEADER_UID" NUMBER, 
	"INS_TIMESTAMP" DATE, 
	"INS_USER" VARCHAR2(30 BYTE), 
	"LAST_UPD_USER" VARCHAR2(30 BYTE), 
	"UPD_DATE_TIMESTAMP" DATE, 
	"COMMENT_TYPE1" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE2" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE3" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE4" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE5" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE6" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE7" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE8" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE9" VARCHAR2(10 BYTE), 
	"COMMENT_TYPE10" VARCHAR2(10 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_STERLING_COMMENT_STG" TO "RO_HBG_INTEGRATION";