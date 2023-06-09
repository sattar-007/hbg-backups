--------------------------------------------------------
--  DDL for Table HBG_PIM_INTEGRATION_LOGS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_PIM_INTEGRATION_LOGS" 
   (	"LOG_ID" NUMBER DEFAULT "HBG_INTEGRATION"."HBG_PIM_INTEGRATION_LOGS_SEQ"."NEXTVAL", 
	"LOG_DATE" TIMESTAMP (6), 
	"LOG_TYPE" VARCHAR2(50 BYTE), 
	"LOG_MESSAGE" VARCHAR2(4000 BYTE), 
	"OIC_INSTANCE_ID" NUMBER(20,0), 
	"HBG_PROCESS_ID" NUMBER(20,0)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
