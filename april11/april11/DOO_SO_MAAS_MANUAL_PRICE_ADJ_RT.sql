--------------------------------------------------------
--  DDL for Type DOO_SO_MAAS_MANUAL_PRICE_ADJ_RT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."DOO_SO_MAAS_MANUAL_PRICE_ADJ_RT" FORCE AS OBJECT
(
    SOURCE_TRANSACTION_ID            VARCHAR2 (200),
    REASON                           VARCHAR2 (4000),
    PRICE_PERIODICITY                VARCHAR2 (4000),
    ADJUSTMENT_TYPE                  VARCHAR2 (4000),
    SOURCE_TRANSACTION_SYSTEM        VARCHAR2 (120),
    SOURCE_TRANSACTION_LINE_ID       VARCHAR2 (200),
    SOURCE_TRANSACTION_SCHEDULE_ID   VARCHAR2 (200),
    CHARGE_DEFINITION                VARCHAR2 (4000),
    ADJUSTMENT_AMOUNT                NUMBER,
    ADJUSTMENT_TYPE_CODE             VARCHAR2 (120),
    ADJUSTMENT_ELEMENT_BASIS         VARCHAR2 (120),
    ADJUSTMENT_ELEMENT_BASIS_CODE    VARCHAR2 (4000),
    REASON_CODE                      VARCHAR2 (120),
    COMMENTS                         VARCHAR2 (4000),
    SEQUENCE                         NUMBER,
    CHARGE_DEFINITION_CODE           VARCHAR2 (120),
    PRICE_PERIODICITY_CODE           VARCHAR2 (120),
    CHARGE_ROLLUP_FLAG               VARCHAR2 (4),
    VALIDATION_STATUS_CODE           VARCHAR2 (120),
    SOURCE_MANUAL_PRICE_ADJ_ID       VARCHAR2 (200),
    CONSTRUCTOR FUNCTION "DOO_SO_MAAS_MANUAL_PRICE_ADJ_RT" RETURN SELF AS RESULT
);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."DOO_SO_MAAS_MANUAL_PRICE_ADJ_RT" 
AS
    CONSTRUCTOR FUNCTION "DOO_SO_MAAS_MANUAL_PRICE_ADJ_RT"
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/
