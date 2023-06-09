--------------------------------------------------------
--  DDL for Index XXDOO_ORD_HDRS_ALL_EFF_B_INT_N1
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."XXDOO_ORD_HDRS_ALL_EFF_B_INT_N1" ON "HBG_INTEGRATION"."XXDOO_ORDER_HDRS_ALL_EFF_B_INT" ("SOURCE_TRANSACTION_ID", "SOURCE_TRANSACTION_SYSTEM", "LOAD_REQUEST_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE( INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;
