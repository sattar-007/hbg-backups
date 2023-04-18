--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_BISAC_EXTRACT_BKP
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_BISAC_EXTRACT_BKP" 
   (	"ISBN" VARCHAR2(100 BYTE), 
	"BISAC_SEQUENCE" VARCHAR2(100 BYTE), 
	"GENBISAC_CODE" VARCHAR2(100 BYTE), 
	"GENBISAC_NAME" VARCHAR2(100 BYTE), 
	"SPCBISAC_CODE" VARCHAR2(100 BYTE), 
	"SPCBISAC_NAME" VARCHAR2(200 BYTE), 
	"STATUS" VARCHAR2(30 BYTE), 
	"INSTANCEID" NUMBER, 
	"COMMENTS" VARCHAR2(4000 BYTE), 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_BISAC_EXTRACT_BKP" TO "RO_HBG_INTEGRATION";