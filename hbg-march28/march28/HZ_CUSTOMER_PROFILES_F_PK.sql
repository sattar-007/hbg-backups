--------------------------------------------------------
--  DDL for Index HZ_CUSTOMER_PROFILES_F_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "HBG_INTEGRATION"."HZ_CUSTOMER_PROFILES_F_PK" ON "HBG_INTEGRATION"."HZ_CUSTOMER_PROFILES_F" ("CUST_ACCOUNT_PROFILE_ID", "EFFECTIVE_END_DATE", "EFFECTIVE_START_DATE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
