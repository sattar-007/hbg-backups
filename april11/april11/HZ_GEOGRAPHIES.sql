--------------------------------------------------------
--  DDL for Table HZ_GEOGRAPHIES
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HZ_GEOGRAPHIES" 
   (	"GEOGRAPHY_ID" NUMBER, 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"GEOGRAPHY_TYPE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_NAME" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_USE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_CODE" VARCHAR2(120 BYTE), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"MULTIPLE_PARENT_FLAG" VARCHAR2(4 BYTE), 
	"CREATED_BY_MODULE" VARCHAR2(120 BYTE), 
	"COUNTRY_CODE" VARCHAR2(8 BYTE), 
	"GEOGRAPHY_ELEMENT1" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT1_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT1_CODE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_ELEMENT2" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT2_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT2_CODE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_ELEMENT3" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT3_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT3_CODE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_ELEMENT4" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT4_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT4_CODE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_ELEMENT5" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT5_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT5_CODE" VARCHAR2(120 BYTE), 
	"GEOGRAPHY_ELEMENT6" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT6_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT7" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT7_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT8" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT8_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT9" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT9_ID" NUMBER, 
	"GEOGRAPHY_ELEMENT10" VARCHAR2(1440 BYTE), 
	"GEOGRAPHY_ELEMENT10_ID" NUMBER, 
	"TIMEZONE_CODE" VARCHAR2(256 BYTE), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"REQUEST_ID" NUMBER, 
	"JOB_DEFINITION_NAME" VARCHAR2(400 BYTE), 
	"JOB_DEFINITION_PACKAGE" VARCHAR2(3600 BYTE), 
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
	"ATTRIBUTE16" VARCHAR2(600 BYTE), 
	"ATTRIBUTE17" VARCHAR2(600 BYTE), 
	"ATTRIBUTE18" VARCHAR2(600 BYTE), 
	"ATTRIBUTE19" VARCHAR2(600 BYTE), 
	"ATTRIBUTE20" VARCHAR2(600 BYTE), 
	"ATTRIBUTE21" VARCHAR2(600 BYTE), 
	"ATTRIBUTE22" VARCHAR2(600 BYTE), 
	"ATTRIBUTE23" VARCHAR2(600 BYTE), 
	"ATTRIBUTE24" VARCHAR2(600 BYTE), 
	"ATTRIBUTE25" VARCHAR2(600 BYTE), 
	"ATTRIBUTE26" VARCHAR2(600 BYTE), 
	"ATTRIBUTE27" VARCHAR2(600 BYTE), 
	"ATTRIBUTE28" VARCHAR2(600 BYTE), 
	"ATTRIBUTE29" VARCHAR2(600 BYTE), 
	"ATTRIBUTE30" VARCHAR2(1020 BYTE), 
	"ATTRIBUTE_NUMBER1" NUMBER, 
	"ATTRIBUTE_NUMBER2" NUMBER, 
	"ATTRIBUTE_NUMBER3" NUMBER, 
	"ATTRIBUTE_NUMBER4" NUMBER, 
	"ATTRIBUTE_NUMBER5" NUMBER, 
	"ATTRIBUTE_NUMBER6" NUMBER, 
	"ATTRIBUTE_NUMBER7" NUMBER, 
	"ATTRIBUTE_NUMBER8" NUMBER, 
	"ATTRIBUTE_NUMBER9" NUMBER, 
	"ATTRIBUTE_NUMBER10" NUMBER, 
	"ATTRIBUTE_NUMBER11" NUMBER, 
	"ATTRIBUTE_NUMBER12" NUMBER, 
	"ATTRIBUTE_DATE1" DATE, 
	"ATTRIBUTE_DATE2" DATE, 
	"ATTRIBUTE_DATE3" DATE, 
	"ATTRIBUTE_DATE4" DATE, 
	"ATTRIBUTE_DATE5" DATE, 
	"ATTRIBUTE_DATE6" DATE, 
	"ATTRIBUTE_DATE7" DATE, 
	"ATTRIBUTE_DATE8" DATE, 
	"ATTRIBUTE_DATE9" DATE, 
	"ATTRIBUTE_DATE10" DATE, 
	"ATTRIBUTE_DATE11" DATE, 
	"ATTRIBUTE_DATE12" DATE, 
	"GEOCODE_FLAG" VARCHAR2(4 BYTE), 
	"GEOGRAPHY_NUMBER" VARCHAR2(960 BYTE), 
	"HIDDEN_FLAG" VARCHAR2(4 BYTE), 
	"SEED_DATA_SOURCE" VARCHAR2(2048 BYTE), 
	"DEFAULT_GEO_PROVIDER" VARCHAR2(120 BYTE), 
	"DEFAULT_GEO_VERSION" VARCHAR2(960 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HZ_GEOGRAPHIES" TO "RO_HBG_INTEGRATION";