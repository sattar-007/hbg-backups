--------------------------------------------------------
--  DDL for Table HBG_PIM_PCC_STG_BKP
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_PIM_PCC_STG_BKP" 
   (	"ISBN13" VARCHAR2(13 BYTE), 
	"PO_NUMBER" VARCHAR2(40 BYTE), 
	"COMPONENT_SUFFIX" VARCHAR2(50 BYTE), 
	"PRINT_RUN" NUMBER(*,0), 
	"PO_COST_IND" VARCHAR2(5 BYTE), 
	"WO_COST_IND" VARCHAR2(5 BYTE), 
	"LONG_TITLE" NVARCHAR2(87), 
	"DBCS_CREATE_TIMESTAMP" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(240 BYTE), 
	"DBCS_UPDATE_TIMESTAMP" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(240 BYTE), 
	"HBG_PROCESS_ID" NUMBER(20,0)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
