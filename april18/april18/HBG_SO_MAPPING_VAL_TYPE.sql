--------------------------------------------------------
--  DDL for Type HBG_SO_MAPPING_VAL_TYPE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_SO_MAPPING_VAL_TYPE" AS OBJECT 
(
SourceOrderSystem VARCHAR2(200),
SourceOrderId VARCHAR2(200),
SourceLineId VARCHAR2(200),
SourceKey VARCHAR2(200),
sales_force VARCHAR2(200),
division VARCHAR2(200),
territory VARCHAR2(200),
sales_rep VARCHAR2(200),
account_number VARCHAR2(200),
order_number VARCHAR2(200),
fulfill_line_id NUMBER
);

/
