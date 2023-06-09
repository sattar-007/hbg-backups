--------------------------------------------------------
--  DDL for Table FND_PROFILE_OPTION_VALUES
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."FND_PROFILE_OPTION_VALUES" 
   (	"ENTERPRISE_ID" NUMBER, 
	"APPLICATION_ID" NUMBER, 
	"PROFILE_OPTION_ID" NUMBER, 
	"LEVEL_NAME" VARCHAR2(120 BYTE), 
	"LEVEL_VALUE" VARCHAR2(4000 BYTE), 
	"PROFILE_OPTION_VALUE" VARCHAR2(4000 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"SEED_DATA_SOURCE" VARCHAR2(2048 BYTE), 
	"ORA_SEED_SET1" VARCHAR2(4 BYTE), 
	"ORA_SEED_SET2" VARCHAR2(4 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."FND_PROFILE_OPTION_VALUES" TO "RO_HBG_INTEGRATION";
