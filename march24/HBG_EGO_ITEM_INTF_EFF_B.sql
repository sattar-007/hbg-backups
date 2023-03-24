--------------------------------------------------------
--  DDL for Table HBG_EGO_ITEM_INTF_EFF_B
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_EGO_ITEM_INTF_EFF_B" 
   (	"TRANSACTION_TYPE" VARCHAR2(10 BYTE), 
	"BATCH_ID" NUMBER(18,0), 
	"BATCH_NUMBER" VARCHAR2(40 BYTE), 
	"ITEM_NUMBER" VARCHAR2(820 BYTE), 
	"ORGANIZATION_CODE" VARCHAR2(18 BYTE), 
	"SOURCE_SYSTEM_CODE" VARCHAR2(30 BYTE), 
	"SOURCE_SYSTEM_REFERENCE" VARCHAR2(255 BYTE), 
	"CONTEXT_CODE" VARCHAR2(80 BYTE), 
	"ATTRIBUTE_CHAR1" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR2" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR3" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR4" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR5" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR6" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR7" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR8" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR9" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR10" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR11" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR12" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR13" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR14" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR15" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR16" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR17" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR18" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR19" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR20" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_NUMBER1" NUMBER, 
	"ATTRIBUTE_NUMBER2" NUMBER, 
	"ATTRIBUTE_NUMBER3" NUMBER, 
	"ATTRIBUTE_NUMBER4" NUMBER, 
	"ATTRIBUTE_NUMBER5" NUMBER, 
	"ATTRIBUTE_NUMBER6" NUMBER, 
	"ATTRIBUTE_NUMBER7" NUMBER, 
	"ATTRIBUTE_NUMBER8" NUMBER, 
	"ATTRIBUTE_NUMBER9" NUMBER, 
	"ATTRIBUTE_NUMBER10" NUMBER, 
	"ATTRIBUTE_DATE1" DATE, 
	"ATTRIBUTE_DATE2" DATE, 
	"ATTRIBUTE_DATE3" DATE, 
	"ATTRIBUTE_DATE4" DATE, 
	"ATTRIBUTE_DATE5" DATE, 
	"ATTRIBUTE_CHAR21" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR22" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR23" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR24" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR25" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR26" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR27" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR28" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR29" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR30" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR31" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR32" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR33" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR34" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR35" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR36" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR37" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR38" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR39" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_CHAR40" VARCHAR2(4000 BYTE), 
	"ATTRIBUTE_NUMBER11" NUMBER, 
	"ATTRIBUTE_NUMBER12" NUMBER, 
	"ATTRIBUTE_NUMBER13" NUMBER, 
	"ATTRIBUTE_NUMBER14" NUMBER, 
	"ATTRIBUTE_NUMBER15" NUMBER, 
	"ATTRIBUTE_NUMBER16" NUMBER, 
	"ATTRIBUTE_NUMBER17" NUMBER, 
	"ATTRIBUTE_NUMBER18" NUMBER, 
	"ATTRIBUTE_NUMBER19" NUMBER, 
	"ATTRIBUTE_NUMBER20" NUMBER, 
	"ATTRIBUTE_DATE6" DATE, 
	"ATTRIBUTE_DATE7" DATE, 
	"ATTRIBUTE_DATE8" DATE, 
	"ATTRIBUTE_DATE9" DATE, 
	"ATTRIBUTE_DATE10" DATE, 
	"ATTRIBUTE_TIMESTAMP1" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP2" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP3" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP4" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP5" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP6" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP7" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP8" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP9" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP10" TIMESTAMP (6), 
	"VERSION_START_DATE" DATE, 
	"VERSION_REVISION_CODE" VARCHAR2(18 BYTE), 
	"ATTRIBUTE_NUMBER1_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER2_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER3_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER4_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER5_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER6_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER7_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER8_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER9_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER10_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER11_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER12_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER13_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER14_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER15_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER16_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER17_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER18_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER19_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER20_UOM_NAME" VARCHAR2(25 BYTE), 
	"ATTRIBUTE_NUMBER1_UE" NUMBER, 
	"ATTRIBUTE_NUMBER2_UE" NUMBER, 
	"ATTRIBUTE_NUMBER3_UE" NUMBER, 
	"ATTRIBUTE_NUMBER4_UE" NUMBER, 
	"ATTRIBUTE_NUMBER5_UE" NUMBER, 
	"ATTRIBUTE_NUMBER6_UE" NUMBER, 
	"ATTRIBUTE_NUMBER7_UE" NUMBER, 
	"ATTRIBUTE_NUMBER8_UE" NUMBER, 
	"ATTRIBUTE_NUMBER9_UE" NUMBER, 
	"ATTRIBUTE_NUMBER10_UE" NUMBER, 
	"ATTRIBUTE_NUMBER11_UE" NUMBER, 
	"ATTRIBUTE_NUMBER12_UE" NUMBER, 
	"ATTRIBUTE_NUMBER13_UE" NUMBER, 
	"ATTRIBUTE_NUMBER14_UE" NUMBER, 
	"ATTRIBUTE_NUMBER15_UE" NUMBER, 
	"ATTRIBUTE_NUMBER16_UE" NUMBER, 
	"ATTRIBUTE_NUMBER17_UE" NUMBER, 
	"ATTRIBUTE_NUMBER18_UE" NUMBER, 
	"ATTRIBUTE_NUMBER19_UE" NUMBER, 
	"ATTRIBUTE_NUMBER20_UE" NUMBER, 
	"STATUS" VARCHAR2(50 BYTE), 
	"ERROR_TEXT" VARCHAR2(4000 BYTE)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_EGO_ITEM_INTF_EFF_B" TO "RO_HBG_INTEGRATION";
