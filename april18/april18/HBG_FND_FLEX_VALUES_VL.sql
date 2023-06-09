--------------------------------------------------------
--  DDL for Table HBG_FND_FLEX_VALUES_VL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_FND_FLEX_VALUES_VL" 
   (	"ROW_ID" ROWID, 
	"FLEX_VALUE_SET_ID" NUMBER, 
	"FLEX_VALUE_ID" NUMBER, 
	"FLEX_VALUE" VARCHAR2(600 BYTE), 
	"ENABLED_FLAG" VARCHAR2(4 BYTE), 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
	"SUMMARY_FLAG" VARCHAR2(120 BYTE), 
	"PARENT_FLEX_VALUE_LOW" VARCHAR2(600 BYTE), 
	"PARENT_FLEX_VALUE_HIGH" VARCHAR2(600 BYTE), 
	"STRUCTURED_HIERARCHY_LEVEL" NUMBER, 
	"HIERARCHY_LEVEL" VARCHAR2(120 BYTE), 
	"COMPILED_VALUE_ATTRIBUTES" VARCHAR2(4000 BYTE), 
	"VALUE_CATEGORY" VARCHAR2(240 BYTE), 
	"ATTRIBUTE1" VARCHAR2(960 BYTE), 
	"ATTRIBUTE2" VARCHAR2(960 BYTE), 
	"ATTRIBUTE3" VARCHAR2(960 BYTE), 
	"ATTRIBUTE4" VARCHAR2(960 BYTE), 
	"ATTRIBUTE5" VARCHAR2(960 BYTE), 
	"ATTRIBUTE6" VARCHAR2(960 BYTE), 
	"ATTRIBUTE7" VARCHAR2(960 BYTE), 
	"ATTRIBUTE8" VARCHAR2(960 BYTE), 
	"ATTRIBUTE9" VARCHAR2(960 BYTE), 
	"ATTRIBUTE10" VARCHAR2(960 BYTE), 
	"ATTRIBUTE11" VARCHAR2(960 BYTE), 
	"ATTRIBUTE12" VARCHAR2(960 BYTE), 
	"ATTRIBUTE13" VARCHAR2(960 BYTE), 
	"ATTRIBUTE14" VARCHAR2(960 BYTE), 
	"ATTRIBUTE15" VARCHAR2(960 BYTE), 
	"ATTRIBUTE16" VARCHAR2(960 BYTE), 
	"ATTRIBUTE17" VARCHAR2(960 BYTE), 
	"ATTRIBUTE18" VARCHAR2(960 BYTE), 
	"ATTRIBUTE19" VARCHAR2(960 BYTE), 
	"ATTRIBUTE20" VARCHAR2(960 BYTE), 
	"ATTRIBUTE21" VARCHAR2(960 BYTE), 
	"ATTRIBUTE22" VARCHAR2(960 BYTE), 
	"ATTRIBUTE23" VARCHAR2(960 BYTE), 
	"ATTRIBUTE24" VARCHAR2(960 BYTE), 
	"ATTRIBUTE25" VARCHAR2(960 BYTE), 
	"ATTRIBUTE26" VARCHAR2(960 BYTE), 
	"ATTRIBUTE27" VARCHAR2(960 BYTE), 
	"ATTRIBUTE28" VARCHAR2(960 BYTE), 
	"ATTRIBUTE29" VARCHAR2(960 BYTE), 
	"ATTRIBUTE30" VARCHAR2(960 BYTE), 
	"ATTRIBUTE31" VARCHAR2(960 BYTE), 
	"ATTRIBUTE32" VARCHAR2(960 BYTE), 
	"ATTRIBUTE33" VARCHAR2(960 BYTE), 
	"ATTRIBUTE34" VARCHAR2(960 BYTE), 
	"ATTRIBUTE35" VARCHAR2(960 BYTE), 
	"ATTRIBUTE36" VARCHAR2(960 BYTE), 
	"ATTRIBUTE37" VARCHAR2(960 BYTE), 
	"ATTRIBUTE38" VARCHAR2(960 BYTE), 
	"ATTRIBUTE39" VARCHAR2(960 BYTE), 
	"ATTRIBUTE40" VARCHAR2(960 BYTE), 
	"ATTRIBUTE41" VARCHAR2(960 BYTE), 
	"ATTRIBUTE42" VARCHAR2(960 BYTE), 
	"ATTRIBUTE43" VARCHAR2(960 BYTE), 
	"ATTRIBUTE44" VARCHAR2(960 BYTE), 
	"ATTRIBUTE45" VARCHAR2(960 BYTE), 
	"ATTRIBUTE46" VARCHAR2(960 BYTE), 
	"ATTRIBUTE47" VARCHAR2(960 BYTE), 
	"ATTRIBUTE48" VARCHAR2(960 BYTE), 
	"ATTRIBUTE49" VARCHAR2(960 BYTE), 
	"ATTRIBUTE50" VARCHAR2(960 BYTE), 
	"ATTRIBUTE_SORT_ORDER" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"FLEX_VALUE_MEANING" VARCHAR2(600 BYTE), 
	"DESCRIPTION" VARCHAR2(960 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_FND_FLEX_VALUES_VL" TO "RO_HBG_INTEGRATION";
