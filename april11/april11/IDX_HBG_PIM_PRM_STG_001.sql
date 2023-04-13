--------------------------------------------------------
--  DDL for Index IDX_HBG_PIM_PRM_STG_001
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX_HBG_PIM_PRM_STG_001" ON "HBG_INTEGRATION"."HBG_PIM_PRM_STG" ("ISBN13") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
