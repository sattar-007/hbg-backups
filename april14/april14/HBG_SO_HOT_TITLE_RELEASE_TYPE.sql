--------------------------------------------------------
--  DDL for Type HBG_SO_HOT_TITLE_RELEASE_TYPE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_RELEASE_TYPE" AS OBJECT 
(
SourceOrderSystem VARCHAR2(200),
SourceOrderId VARCHAR2(200),
SourceLineId VARCHAR2(200),
SourceHoldCode VARCHAR2(200),
HoldReleaseReasonCode VARCHAR2(200),
HoldReleaseComments VARCHAR2(2000)
);

/
