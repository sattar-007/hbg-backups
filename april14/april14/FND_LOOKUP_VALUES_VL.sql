--------------------------------------------------------
--  DDL for Table FND_LOOKUP_VALUES_VL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."FND_LOOKUP_VALUES_VL" 
   (	"ROW_ID" ROWID, 
	"LOOKUP_TYPE" VARCHAR2(120 BYTE), 
	"LOOKUP_CODE" VARCHAR2(120 BYTE), 
	"VIEW_APPLICATION_ID" NUMBER, 
	"SET_ID" NUMBER, 
	"MEANING" VARCHAR2(320 BYTE), 
	"DESCRIPTION" VARCHAR2(960 BYTE), 
	"ENABLED_FLAG" VARCHAR2(4 BYTE), 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
	"DISPLAY_SEQUENCE" NUMBER, 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"TERRITORY_CODE" VARCHAR2(8 BYTE), 
	"ATTRIBUTE_CATEGORY" VARCHAR2(120 BYTE), 
	"ATTRIBUTE1" VARCHAR2(600 BYTE), 
	"ATTRIBUTE2" VARCHAR2(600 BYTE), 
	"ATTRIBUTE3" VARCHAR2(600 BYTE), 
	"ATTRIBUTE4" VARCHAR2(600 BYTE), 
	"ATTRIBUTE5" VARCHAR2(600 BYTE), 
	"ATTRIBUTE6" VARCHAR2(600 BYTE), 
	"ATTRIBUTE7" VARCHAR2(600 BYTE), 
	"ATTRIBUTE8" VARCHAR2(600 BYTE), 
	"ATTRIBUTE9" VARCHAR2(600 BYTE), 
	"ATTRIBUTE10" VARCHAR2(600 BYTE), 
	"ATTRIBUTE11" VARCHAR2(600 BYTE), 
	"ATTRIBUTE12" VARCHAR2(600 BYTE), 
	"ATTRIBUTE13" VARCHAR2(600 BYTE), 
	"ATTRIBUTE14" VARCHAR2(600 BYTE), 
	"ATTRIBUTE15" VARCHAR2(600 BYTE), 
	"TAG" VARCHAR2(600 BYTE), 
	"CHANGE_SINCE_LAST_REFRESH" VARCHAR2(4 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."FND_LOOKUP_VALUES_VL" TO "RO_HBG_INTEGRATION";