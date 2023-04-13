--------------------------------------------------------
--  DDL for Table HBG_ARTRX_ACTIVITY_PROCESS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_ARTRX_ACTIVITY_PROCESS" 
   (	"PROCESS_ID" NUMBER, 
	"ACTIVITY_TYPE" VARCHAR2(50 BYTE), 
	"SUBMITTED_BY" VARCHAR2(50 BYTE), 
	"SESSION_ID" VARCHAR2(50 BYTE), 
	"SUBMISSION_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;