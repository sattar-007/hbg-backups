--------------------------------------------------------
--  DDL for Table AS_SFTP_PRIVATE_KEYS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."AS_SFTP_PRIVATE_KEYS" 
   (	"HOST" VARCHAR2(1000 BYTE), 
	"ID" VARCHAR2(128 BYTE), 
	"KEY" CLOB
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("KEY") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."AS_SFTP_PRIVATE_KEYS" TO "RO_HBG_INTEGRATION";
