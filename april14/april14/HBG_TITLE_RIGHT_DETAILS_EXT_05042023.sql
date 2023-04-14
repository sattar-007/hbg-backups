--------------------------------------------------------
--  DDL for Table HBG_TITLE_RIGHT_DETAILS_EXT_05042023
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_TITLE_RIGHT_DETAILS_EXT_05042023" 
   (	"TITLE_RIGHT_ID" NUMBER, 
	"TITLE_RIGHT_DETAIL_ID" NUMBER, 
	"TITLE_RIGHT_CATEGORY" VARCHAR2(200 BYTE), 
	"COUNTRY_ID" NUMBER, 
	"COUNTRY_GROUP" VARCHAR2(255 BYTE), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
