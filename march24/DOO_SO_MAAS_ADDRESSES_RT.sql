--------------------------------------------------------
--  DDL for Type DOO_SO_MAAS_ADDRESSES_RT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."DOO_SO_MAAS_ADDRESSES_RT" FORCE AS OBJECT
(
    SOURCE_TRANSACTION_ID            VARCHAR2 (200),
    SOURCE_TRANSACTION_SYSTEM        VARCHAR2 (120),
    SOURCE_TRANSACTION_LINE_ID       VARCHAR2 (200),
    SOURCE_TRANSACTION_SCHEDULE_ID   VARCHAR2 (200),
    ADDRESS_USE_TYPE                 VARCHAR2 (120),
    PARTY_ID                         NUMBER,
    PARTY_NUMBER                     VARCHAR2 (120),
    PARTY_NAME                       VARCHAR2 (1440),
    CUSTOMER_ID                      NUMBER,
    CUSTOMER_NUMBER                  VARCHAR2 (120),
    CUSTOMER_NAME                    VARCHAR2 (1440),
    REQUESTED_SUPPLIER_CODE          VARCHAR2 (4000),
    REQUESTED_SUPPLIER_NUMBER        VARCHAR2 (616),
    REQUESTED_SUPPLIER_NAME          VARCHAR2 (4000),
    PARTY_SITE_ID                    VARCHAR2 (120),
    ACCOUNT_SITE_USE_ID              VARCHAR2 (120),
    REQUESTED_SUPPLIER_SITE_ID       VARCHAR2 (120),
    ADDRESS_ORIG_SYS_REFERENCE       VARCHAR2 (1020),
    ADDRESS_LINE1                    VARCHAR2 (960),
    ADDRESS_LINE2                    VARCHAR2 (960),
    ADDRESS_LINE3                    VARCHAR2 (960),
    ADDRESS_LINE4                    VARCHAR2 (960),
    CITY                             VARCHAR2 (240),
    POSTAL_CODE                      VARCHAR2 (240),
    STATE                            VARCHAR2 (240),
    PROVINCE                         VARCHAR2 (240),
    COUNTY                           VARCHAR2 (240),
    COUNTRY                          VARCHAR2 (240),
    SHIP_TO_REQUEST_REGION           VARCHAR2 (1020),
    PARTY_CONTACT_ID                 NUMBER,
    PARTY_CONTACT_NUMBER             VARCHAR2 (120),
    PARTY_CONTACT_NAME               VARCHAR2 (1440),
    PARTY_CONTACT_EMAIL              VARCHAR2 (1280),
    PARTY_PERSON_EMAIL               VARCHAR2 (1280),
    PARTY_ORGANIZATION_EMAIL         VARCHAR2 (1280),
    ACCOUNT_CONTACT_ID               NUMBER,
    ACCOUNT_CONTACT_NUMBER           VARCHAR2 (120),
    ACCOUNT_CONTACT_NAME             VARCHAR2 (1440),
    CONTACT_ORIG_SYS_REFERENCE       VARCHAR2 (1020),
    LOCATION_ID                      NUMBER,
    PREF_CONTACT_POINT_ID            NUMBER,
    PREF_CONT_POINT_ORIG_SYS_REF     VARCHAR2 (960),
    FIRST_NAME                       VARCHAR2 (600),
    LAST_NAME                        VARCHAR2 (600),
    MIDDLE_NAME                      VARCHAR2 (240),
    NAME_SUFFIX                      VARCHAR2 (120),
    TITLE                            VARCHAR2 (240),
    CONTACT_FIRST_NAME               VARCHAR2 (600),
    CONTACT_LAST_NAME                VARCHAR2 (600),
    CONTACT_MIDDLE_NAME              VARCHAR2 (240),
    CONTACT_NAME_SUFFIX              VARCHAR2 (120),
    CONTACT_TITLE                    VARCHAR2 (240),
    PARTY_TYPE                       VARCHAR2 (120),
    DESTINATION_SHIPPING_ORG_ID      NUMBER,
    DESTINATION_SHIPPING_ORG_CODE    VARCHAR2 (72),
    DESTINATION_SHIPPING_ORG_NAME    VARCHAR2 (960),
    BATCH_ID                         NUMBER,
    VALIDATION_BITSET                NUMBER,
    CONSTRUCTOR FUNCTION "DOO_SO_MAAS_ADDRESSES_RT" RETURN SELF AS RESULT
);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."DOO_SO_MAAS_ADDRESSES_RT" 
AS
    CONSTRUCTOR FUNCTION "DOO_SO_MAAS_ADDRESSES_RT"
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/
