--------------------------------------------------------
--  DDL for Index HBG_AUTO_HOLD_SO_HOLDS_EXT_PK1
--------------------------------------------------------

  CREATE UNIQUE INDEX "HBG_INTEGRATION"."HBG_AUTO_HOLD_SO_HOLDS_EXT_PK1" ON "HBG_INTEGRATION"."HBG_AUTO_HOLD_SO_HOLDS_EXT" ("HOLD_INSTANCE_ID", "SOURCE_ORDER_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;