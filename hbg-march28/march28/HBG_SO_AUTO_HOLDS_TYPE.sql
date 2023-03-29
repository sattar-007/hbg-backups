--------------------------------------------------------
--  DDL for Type HBG_SO_AUTO_HOLDS_TYPE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_SO_AUTO_HOLDS_TYPE" AS OBJECT 
(
SourceOrderSystem VARCHAR2(200),
SourceOrderId VARCHAR2(200),
SourceLineId VARCHAR2(200),
SourceHoldCode VARCHAR2(200),
HoldComments VARCHAR2(2000),
HoldReleaseReasonCode VARCHAR2(200),
HoldReleaseComments VARCHAR2(2000),
HOLDFLAG VARCHAR2(20),
account_number VARCHAR2(200),
order_number VARCHAR2(200)
);

/
