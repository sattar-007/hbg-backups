--------------------------------------------------------
--  DDL for Table HBG_PROCESS_ORDERS_PAYMENT_TKN_FBDI
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_PAYMENT_TKN_FBDI" 
   (	"SOURCE_TRANSACTION_SYSTEM" VARCHAR2(30 BYTE), 
	"SOURCE_TRANSACTION_ID" VARCHAR2(50 BYTE), 
	"SOURCE_TRANSACTION_LINE_ID" VARCHAR2(50 BYTE), 
	"SOURCE_TRANSACTION_SCHEDULE_ID" VARCHAR2(50 BYTE), 
	"PAYMENT_METHOD_CODE" VARCHAR2(1000 BYTE), 
	"PAYMENT_METHOD" VARCHAR2(1000 BYTE), 
	"PAYMENT_TRANSACTION_ID" NUMBER(18,0), 
	"PAYMENT_SET_ID" NUMBER(18,0), 
	"SOURCE_TRANSACTION_PAYMENT_ID" VARCHAR2(50 BYTE), 
	"PAYMENT_TYPE" VARCHAR2(80 BYTE), 
	"PAYMENT_TYPE_CODE" VARCHAR2(30 BYTE), 
	"CC_TOKEN_NUMBER" VARCHAR2(30 BYTE), 
	"CC_EXPIRATION_DATE" VARCHAR2(19 BYTE), 
	"CC_FIRST_NAME" VARCHAR2(40 BYTE), 
	"CC_LAST_NAME" VARCHAR2(40 BYTE), 
	"CC_ISSUER_CODE" VARCHAR2(30 BYTE), 
	"CC_MASKED_NUMBER" VARCHAR2(30 BYTE), 
	"CC_AUTH_REQUEST_ID" VARCHAR2(30 BYTE), 
	"CC_VOICE_AUTH_CODE" VARCHAR2(100 BYTE), 
	"PAYMENT_SERVER_ORDER_NUM" VARCHAR2(80 BYTE), 
	"AUTHORIZED_AMOUNT" NUMBER, 
	"CREATION_DATE" DATE, 
	"LAST_UPDATE_DATE" DATE, 
	"CREATED_BY" VARCHAR2(360 BYTE), 
	"LAST_UPDATED_BY" VARCHAR2(360 BYTE), 
	"STATUS" VARCHAR2(360 BYTE), 
	"ERROR_MSG" VARCHAR2(1000 BYTE), 
	"GIS_ID" NUMBER, 
	"SOURCE_SYSTEM" VARCHAR2(20 BYTE), 
	"SBI_UUID" VARCHAR2(50 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
