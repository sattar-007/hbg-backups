--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_CATALOGS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_CATALOGS" 
   (	"ID" VARCHAR2(30 BYTE), 
	"DISPLAYNAME" VARCHAR2(100 BYTE), 
	"ROOTNAVIGABLECATEGORY" VARCHAR2(30 BYTE), 
	"ROOTNONNAVIGABLECATEGORY" VARCHAR2(30 BYTE), 
	"DEFAULTCATEGORYFORPRODUCTS" VARCHAR2(30 BYTE), 
	"BASECATALOG" VARCHAR2(30 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_CATALOGS" TO "RO_HBG_INTEGRATION";
