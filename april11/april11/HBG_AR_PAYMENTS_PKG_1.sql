--------------------------------------------------------
--  DDL for Package Body HBG_AR_PAYMENTS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_AR_PAYMENTS_PKG" IS
/*
--
-- $Header: HBG_AR_PAYMENTS_PKG.sql
--
-- Copyright (c) 2022, by Peloton Consulting Group, All Rights Reserved
--
-- Author          : Emanuel Reis - Peloton Consulting Group
-- Component Id    : HBG_AR_PAYMENTS_PKG
-- Script Location : 
-- Description     :
-- Package Usage   : Package responsible for transforming and loading data for the AR Payments Integration.
--
-- Name                               Type        Purpose
-- --------------------------------   ----------  ----------------------------------------------------
-- MAIN                               Procedure   Procedure to start the data validation, transforming and loading.
--
-- History:
-- Name                 Date          Version    Description
-- ------------------   ------------  --------   ------------------------------------------------------------------------
-- Emanuel Reis         25-JAN-2022   1.0        Original Version
--
*/  
   /*Global Variables*/

  PROCEDURE MAIN (P_OIC_INSTANCE_ID IN VARCHAR2
                , P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE) IS

  BEGIN

  NULL;

  END MAIN;

  FUNCTION GET_LIST_OF_ACCOUNTS_F(P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE) 
                                  RETURN LIST_OF_ACCOUNT_TYPE PIPELINED IS                                  

  CURSOR C_PAYMENT_LINES(PN_BATCH_ID IN HBG_AR_PAYMENTS_LINES.BATCH_ID%TYPE) 
      IS
  SELECT ACCOUNT_NUMBER
    FROM HBG_AR_PAYMENTS_LINES
   WHERE BATCH_ID = PN_BATCH_ID
     AND ACCOUNT_NUMBER IS NOT NULL
   GROUP BY ACCOUNT_NUMBER;

   L_LIST_OF_ACCOUNT_REC LIST_OF_ACCOUNT_REC;  
   R_PAYMENT_LINES C_PAYMENT_LINES%ROWTYPE;
   L_COUNT NUMBER := 0;

  BEGIN

    L_LIST_OF_ACCOUNT_REC := NULL;
    L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS := NULL;
    L_COUNT               := 0;

    OPEN C_PAYMENT_LINES(P_BATCH_ID);
        LOOP

            FETCH C_PAYMENT_LINES INTO R_PAYMENT_LINES;
            EXIT WHEN C_PAYMENT_LINES%NOTFOUND;

            IF L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS IS NULL THEN

                L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS := R_PAYMENT_LINES.ACCOUNT_NUMBER;

            ELSE

                L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS := L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS ||','||
                                                          R_PAYMENT_LINES.ACCOUNT_NUMBER;

            END IF;

            L_COUNT := L_COUNT +1;

            IF L_COUNT >= 900 THEN
                PIPE ROW(L_LIST_OF_ACCOUNT_REC);
                L_COUNT := 0;
                L_LIST_OF_ACCOUNT_REC := NULL;
                L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS := NULL;
            END IF;

        END LOOP; 

    CLOSE C_PAYMENT_LINES;

    IF L_LIST_OF_ACCOUNT_REC.LIST_OF_ACCOUNTS IS NOT NULL THEN
            PIPE ROW(L_LIST_OF_ACCOUNT_REC);
    END IF;

  END GET_LIST_OF_ACCOUNTS_F;

  PROCEDURE UPDATE_PAYMENT_LINE_STATUS_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                                        , P_ACCOUNT_NUMBER IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE
                                        , P_RETURN_STATUS  IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE
                                        , P_RETURN_MESSAGE IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE) IS
  BEGIN
    UPDATE HBG_AR_PAYMENTS_LINES
       SET RETURN_STATUS    = P_RETURN_STATUS
          ,RETURN_MESSAGE   = P_RETURN_MESSAGE
          ,LAST_UPDATED_BY  = 'OIC INTEGRATION'
          ,LAST_UPDATE_DATE = SYSDATE
     WHERE ACCOUNT_NUMBER = NVL(P_ACCOUNT_NUMBER, 'X')
       AND BATCH_ID       = P_BATCH_ID
       AND NVL(RETURN_STATUS, 'X') != 'PROCESSED';

       COMMIT;

  EXCEPTION
   WHEN OTHERS THEN 
   ROLLBACK;
   RAISE_APPLICATION_ERROR(-20111,'Error trying to update row '||SQLERRM);
  END UPDATE_PAYMENT_LINE_STATUS_P;

  PROCEDURE VALIDATE_CUSTOMER_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                                ,P_USER IN VARCHAR2)
  IS

  BEGIN

      UPDATE HBG_AR_PAYMENTS_LINES HAPL
         SET RETURN_STATUS    = 'ERROR'
           , RETURN_MESSAGE   = 'Customer account number does not have a matching customer account active in Oracle Cloud Fusion.'
           , LAST_UPDATED_BY  = P_USER
           , LAST_UPDATE_DATE = SYSDATE 
       WHERE NVL(HAPL.RETURN_STATUS, 'X')!= 'PROCESSED'
         AND HAPL.BATCH_ID                = P_BATCH_ID
         AND HAPL.ACCOUNT_NUMBER         IS NOT NULL
         AND NOT EXISTS (SELECT 1 
                           FROM HZ_CUST_ACCOUNTS
                          WHERE ACCOUNT_NUMBER = HAPL.ACCOUNT_NUMBER
                            AND NVL(STATUS,'X')= 'A');
         COMMIT;
  EXCEPTION 
    WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20111,'Error trying to validate customer account number '||SQLERRM);
  END VALIDATE_CUSTOMER_P ;

  PROCEDURE HBG_PAYMENT_EXTENSION_CREATE ( P_BATCH_ID         IN HBG_AR_PAYMENTS_LINES.BATCH_ID%TYPE
                                          ,P_BUSINESS_UNIT    IN HBG_AR_PAYMENTS_LINES.BUSINESS_UNIT%TYPE
                                          ,P_PAYMENT_TYPE     IN HBG_AR_PAYMENTS_LINES.PAYMENT_TYPE%TYPE
                                          ,P_PAYMENT_DATE     IN HBG_AR_PAYMENTS_LINES.PAYMENT_DATE%TYPE
                                          ,P_ACCOUNT_NUMBER   IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE
                                          ,P_ACCOUNT_NAME     IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NAME%TYPE
                                          ,P_RECEIPT_NUMBER   IN HBG_AR_PAYMENTS_LINES.RECEIPT_NUMBER%TYPE
                                          ,P_AMOUNT           IN HBG_AR_PAYMENTS_LINES.AMOUNT%TYPE
                                          ,P_PAYMENT_METHOD   IN HBG_AR_PAYMENTS_LINES.PAYMENT_METHOD%TYPE
                                          ,P_CURRENCY         IN HBG_AR_PAYMENTS_LINES.CURRENCY%TYPE
                                          ,P_GL_ACCOUNT       IN HBG_AR_PAYMENTS_LINES.GL_ACCOUNT%TYPE
                                          ,P_CREATED_BY       IN HBG_AR_PAYMENTS_LINES.CREATED_BY%TYPE
                                          ,P_LAST_UPDATED_BY  IN HBG_AR_PAYMENTS_LINES.LAST_UPDATED_BY%TYPE
                                          ,P_CREATE_STATUS    OUT VARCHAR2
                                          ,P_LINE_ID_OUT OUT NUMBER) IS
  BEGIN
    P_LINE_ID_OUT := SQ_PAYMENTS_LINE_ID.NEXTVAL;
    INSERT INTO 
      HBG_AR_PAYMENTS_LINES( 
         LINE_ID         
        ,BATCH_ID        
        ,BUSINESS_UNIT   
        ,PAYMENT_TYPE    
        ,PAYMENT_DATE    
        ,ACCOUNT_NUMBER  
        ,ACCOUNT_NAME    
        ,RECEIPT_NUMBER  
        ,AMOUNT          
        ,PAYMENT_METHOD  
        ,CURRENCY        
        ,GL_ACCOUNT      
        ,CREATION_DATE   
        ,CREATED_BY      
        ,LAST_UPDATE_DATE
        ,LAST_UPDATED_BY 
        ,RETURN_STATUS   
        ,RETURN_MESSAGE)
    VALUES(
       P_LINE_ID_OUT     
      ,P_BATCH_ID        
      ,P_BUSINESS_UNIT   
      ,P_PAYMENT_TYPE    
      ,P_PAYMENT_DATE    
      ,P_ACCOUNT_NUMBER  
      ,P_ACCOUNT_NAME    
      ,P_RECEIPT_NUMBER  
      ,P_AMOUNT          
      ,P_PAYMENT_METHOD  
      ,P_CURRENCY        
      ,P_GL_ACCOUNT      
      ,sysdate   
      ,P_CREATED_BY      
      ,sysdate
      ,P_LAST_UPDATED_BY 
      ,'DRAFT'
      ,NULL);


    P_CREATE_STATUS := 'SUCCESS';
    COMMIT;
  EXCEPTION
   WHEN OTHERS THEN 
   ROLLBACK;
    P_CREATE_STATUS := 'Error trying to create row: ' || SQLERRM;
  END HBG_PAYMENT_EXTENSION_CREATE;

  PROCEDURE MERGE_HEADER_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                           ,P_CREATED_BY IN HBG_AR_PAYMENTS_HEADER.CREATED_BY%TYPE
                           ,P_CREATION_DATE IN HBG_AR_PAYMENTS_HEADER.CREATION_DATE%TYPE
                           ,P_LAST_UPDATED_BY IN HBG_AR_PAYMENTS_HEADER.LAST_UPDATED_BY%TYPE
                           ,P_LAST_UPDATE_DATE IN HBG_AR_PAYMENTS_HEADER.LAST_UPDATE_DATE%TYPE
                           ,P_CREATE_STATUS OUT VARCHAR2) IS

  L_HEADER_VALUES HBG_AR_PAYMENTS_HEADER%ROWTYPE;


  BEGIN

    L_HEADER_VALUES                  := NULL;

    L_HEADER_VALUES.BATCH_ID         := P_BATCH_ID;
    -- L_HEADER_VALUES.STATUS           := P_STATUS;
    L_HEADER_VALUES.CREATED_BY       := P_CREATED_BY;
    L_HEADER_VALUES.LAST_UPDATED_BY  := P_LAST_UPDATED_BY;
    L_HEADER_VALUES.CREATION_DATE    := P_CREATION_DATE;
    L_HEADER_VALUES.LAST_UPDATE_DATE := P_LAST_UPDATE_DATE;

    MERGE 
     INTO HBG_AR_PAYMENTS_HEADER
    USING (SELECT NVL(L_HEADER_VALUES.BATCH_ID, -999) BATCH_ID
             FROM DUAL) HEADER_SUBQUERY
       ON (HBG_AR_PAYMENTS_HEADER.BATCH_ID = HEADER_SUBQUERY.BATCH_ID)
     /*WHEN MATCHED
     THEN UPDATE SET
        HBG_AR_PAYMENTS_HEADER.STATUS           = L_HEADER_VALUES.STATUS
       ,HBG_AR_PAYMENTS_HEADER.LAST_UPDATED_BY  = L_HEADER_VALUES.LAST_UPDATED_BY
       ,HBG_AR_PAYMENTS_HEADER.LAST_UPDATE_DATE = SYSDATE*/
     WHEN NOT MATCHED
     THEN INSERT VALUES L_HEADER_VALUES;

     COMMIT;

     P_CREATE_STATUS := 'SUCESS';

  EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    P_CREATE_STATUS := 'ERROR';
    RAISE_APPLICATION_ERROR(-20059,  SUBSTR('SQL Error: ' || SQLERRM || '; SQL Back Trace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000));
  END MERGE_HEADER_P;

  PROCEDURE MERGE_LINE_P (  P_LINE_ID IN HBG_AR_PAYMENTS_LINES.LINE_ID%TYPE,
                            P_BATCH_ID IN HBG_AR_PAYMENTS_LINES.LINE_ID%TYPE,
                            P_BUSINESS_UNIT IN HBG_AR_PAYMENTS_LINES.BUSINESS_UNIT%TYPE,
                            P_PROCESS_TYPE  IN HBG_AR_PAYMENTS_LINES.PROCESS_TYPE%TYPE,
                            P_PAYMENT_TYPE  IN HBG_AR_PAYMENTS_LINES.PAYMENT_TYPE%TYPE,
                            P_PAYMENT_DATE  IN HBG_AR_PAYMENTS_LINES.PAYMENT_DATE%TYPE,
                            P_ACCOUNT_NUMBER  IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE,
                            P_ACCOUNT_NAME  IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NAME%TYPE,
                            P_RECEIPT_NUMBER IN HBG_AR_PAYMENTS_LINES.RECEIPT_NUMBER%TYPE,
                            P_INVOICE_NUMBER  IN HBG_AR_PAYMENTS_LINES.INVOICE_NUMBER%TYPE,
                            P_CLAIM_NUMBER IN HBG_AR_PAYMENTS_LINES.CLAIM_NUMBER%TYPE,
                            P_TRANSACTION_CODE IN HBG_AR_PAYMENTS_LINES.TRANSACTION_CODE%TYPE,
                            P_AMOUNT  IN HBG_AR_PAYMENTS_LINES.AMOUNT%TYPE,
                            P_PAYMENT_METHOD IN HBG_AR_PAYMENTS_LINES.PAYMENT_METHOD%TYPE,
                            P_CURRENCY  IN HBG_AR_PAYMENTS_LINES.CURRENCY%TYPE,
                            P_GL_ACCOUNT  IN HBG_AR_PAYMENTS_LINES.GL_ACCOUNT%TYPE,
                            P_RECEIPT_ID  IN HBG_AR_PAYMENTS_LINES.RECEIPT_ID%TYPE,
                            P_PAYMENT_ID  IN HBG_AR_PAYMENTS_LINES.PAYMENT_ID%TYPE,
                            P_CLAIM_ID  IN HBG_AR_PAYMENTS_LINES.CLAIM_ID%TYPE,
                            P_CREATION_DATE  IN HBG_AR_PAYMENTS_LINES.CREATION_DATE%TYPE,
                            P_CREATED_BY  IN HBG_AR_PAYMENTS_LINES.CREATED_BY%TYPE,
                            P_LAST_UPDATE_DATE   IN HBG_AR_PAYMENTS_LINES.LAST_UPDATE_DATE%TYPE,
                            P_LAST_UPDATED_BY  IN HBG_AR_PAYMENTS_LINES.LAST_UPDATED_BY%TYPE,
                            P_RETURN_STATUS  IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE,
                            P_RETURN_MESSAGE  IN HBG_AR_PAYMENTS_LINES.RETURN_MESSAGE%TYPE,
                            P_CREATE_STATUS    OUT VARCHAR2,
                            P_LINE_ID_OUT OUT NUMBER) IS
  L_COUNT NUMBER := 0;

  BEGIN

    L_COUNT := 0;

    BEGIN
        SELECT COUNT(1)
          INTO L_COUNT
          FROM HBG_AR_PAYMENTS_LINES
         WHERE LINE_ID = NVL(P_LINE_ID, -999);
    EXCEPTION 
        WHEN OTHERS THEN
            L_COUNT := 1;
            P_CREATE_STATUS := 'ERROR TRYING TO VERIFY IF LINE EXISTS ALREADY: '||SQLERRM;
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20059,  SUBSTR('SQL Error: ' || SQLERRM || '; SQL Back Trace: ' 
                                        || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000));
    END;

    IF NVL(L_COUNT, 0) > 0 THEN

        BEGIN
         UPDATE HBG_AR_PAYMENTS_LINES 
            SET BUSINESS_UNIT    = P_BUSINESS_UNIT
               ,PAYMENT_TYPE     = P_PAYMENT_TYPE
               ,PAYMENT_DATE     = P_PAYMENT_DATE
               ,ACCOUNT_NUMBER   = P_ACCOUNT_NUMBER
               ,ACCOUNT_NAME     = P_ACCOUNT_NAME
               ,RECEIPT_NUMBER   = P_RECEIPT_NUMBER
               ,AMOUNT           = P_AMOUNT
               ,PAYMENT_METHOD   = P_PAYMENT_METHOD
               ,CURRENCY         = P_CURRENCY
               ,GL_ACCOUNT       = P_GL_ACCOUNT
               ,RETURN_STATUS    = P_RETURN_STATUS
               ,RETURN_MESSAGE   = P_RETURN_MESSAGE
               ,LAST_UPDATED_BY  = P_LAST_UPDATED_BY
               ,LAST_UPDATE_DATE = P_LAST_UPDATE_DATE
          WHERE LINE_ID = NVL(P_LINE_ID, -999);

          P_LINE_ID_OUT := P_LINE_ID;

        EXCEPTION 
            WHEN OTHERS THEN
                ROLLBACK;
                P_CREATE_STATUS := 'ERROR UPDATING LINE: '||SQLERRM;
                RAISE_APPLICATION_ERROR(-20059,  SUBSTR('SQL Error: ' || SQLERRM || '; SQL Back Trace: ' 
                                    || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000));
        END;

    ELSIF NVL(L_COUNT, 0) = 0 THEN
        BEGIN
            INSERT 
              INTO HBG_AR_PAYMENTS_LINES
                   (BATCH_ID,
                    BUSINESS_UNIT,
                    PROCESS_TYPE ,
                    PAYMENT_TYPE ,
                    PAYMENT_DATE ,
                    ACCOUNT_NUMBER ,
                    ACCOUNT_NAME ,
                    RECEIPT_NUMBER,
                    INVOICE_NUMBER ,
                    CLAIM_NUMBER,
                    TRANSACTION_CODE,
                    AMOUNT ,
                    PAYMENT_METHOD,
                    CURRENCY ,
                    GL_ACCOUNT ,
                    RECEIPT_ID ,
                    PAYMENT_ID,
                    CLAIM_ID ,
                    CREATION_DATE ,
                    CREATED_BY ,
                    LAST_UPDATE_DATE  ,
                    LAST_UPDATED_BY ,
                    RETURN_STATUS ,
                    RETURN_MESSAGE )
            VALUES (P_BATCH_ID,
                    P_BUSINESS_UNIT,
                    P_PROCESS_TYPE ,
                    P_PAYMENT_TYPE ,
                    P_PAYMENT_DATE ,
                    P_ACCOUNT_NUMBER ,
                    P_ACCOUNT_NAME ,
                    P_RECEIPT_NUMBER,
                    P_INVOICE_NUMBER ,
                    P_CLAIM_NUMBER,
                    P_TRANSACTION_CODE,
                    P_AMOUNT ,
                    P_PAYMENT_METHOD,
                    P_CURRENCY ,
                    P_GL_ACCOUNT ,
                    P_RECEIPT_ID ,
                    P_PAYMENT_ID,
                    P_CLAIM_ID ,
                    P_CREATION_DATE ,
                    P_CREATED_BY ,
                    P_LAST_UPDATE_DATE  ,
                    P_LAST_UPDATED_BY ,
                    P_RETURN_STATUS ,
                    P_RETURN_MESSAGE ) RETURNING LINE_ID INTO P_LINE_ID_OUT;
         EXCEPTION
            WHEN OTHERS THEN
            ROLLBACK;
            P_CREATE_STATUS := 'ERROR CREATING LINE: '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20059,  SUBSTR('SQL Error: ' || SQLERRM || '; SQL Back Trace: ' 
                                        || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000));            
        END;
    END IF;

    COMMIT;
    P_CREATE_STATUS := 'SUCCESS';

  EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20059,  SUBSTR('SQL Error: ' || SQLERRM || '; SQL Back Trace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000));
  END MERGE_LINE_P;

  PROCEDURE CREATE_SCHEDULE_P (P_BATCH_ID IN HBG_AR_PAYMENTS_SCHEDULE.BATCH_ID%TYPE
                              ,P_OIC_INTEGRATION_ID IN HBG_AR_PAYMENTS_SCHEDULE.OIC_INTEGRATION_ID%TYPE
                              ,P_NUMBER_OF_PARALLEL IN NUMBER
                              ,P_PROCESS_TYPE IN HBG_AR_PAYMENTS_SCHEDULE.PROCESS_TYPE%TYPE
                              ,P_PAYMENT_TYPE IN HBG_AR_PAYMENTS_SCHEDULE.PAYMENT_TYPE%TYPE
                              ,P_STATUS OUT VARCHAR2
                              ,P_MESSAGE OUT VARCHAR2) IS

  L_RECORD_COUNT NUMBER := 0;


  BEGIN

    P_STATUS  := 'SUCESS';
    P_MESSAGE := 'Schedule created successfully';

    BEGIN
        SELECT COUNT(1)
          INTO L_RECORD_COUNT
          FROM HBG_AR_PAYMENTS_LINES
         WHERE BATCH_ID             = NVL(P_BATCH_ID, -999)
           AND RETURN_STATUS        = 'PROCESSING'
           AND UPPER(PROCESS_TYPE)  = UPPER(P_PROCESS_TYPE)
           AND UPPER(PAYMENT_TYPE)  = UPPER(P_PAYMENT_TYPE); 
    EXCEPTION 
        WHEN OTHERS THEN
            L_RECORD_COUNT := 0;
    END;

    IF L_RECORD_COUNT = 0 THEN
            P_STATUS  := 'ERROR';
            P_MESSAGE := 'There are no elligible receipts, payments or claims to submit';
    ELSE

        FOR C_SCHEDULE IN (SELECT PAYMENT_TYPE,
                                  PROCESS_TYPE,
                                  LINE_ID,
                                  NTILE(P_NUMBER_OF_PARALLEL) OVER (ORDER BY LINE_ID) SEQUENCE
                             FROM HBG_AR_PAYMENTS_LINES
                            WHERE BATCH_ID             = NVL(P_BATCH_ID, -999)
                              AND RETURN_STATUS        = 'PROCESSING'
                              AND UPPER(PROCESS_TYPE)  = UPPER(P_PROCESS_TYPE)
                              AND UPPER(PAYMENT_TYPE)  = UPPER(P_PAYMENT_TYPE)) LOOP

            BEGIN
                INSERT 
                  INTO HBG_AR_PAYMENTS_SCHEDULE 
                      (BATCH_ID,
                       OIC_INTEGRATION_ID,
                       PROCESS_TYPE,
                       PAYMENT_TYPE,
                       SEQUENCE,
                       LINE_ID)
                VALUES (P_BATCH_ID,
                        P_OIC_INTEGRATION_ID,
                        C_SCHEDULE.PROCESS_TYPE,
                        C_SCHEDULE.PAYMENT_TYPE,
                        C_SCHEDULE.SEQUENCE,
                        C_SCHEDULE.LINE_ID);
            END;

        END LOOP;

        COMMIT;

    END IF;
  EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK;
         P_STATUS  := 'ERROR';
         P_MESSAGE := SQLERRM;
  END CREATE_SCHEDULE_P;


  PROCEDURE VALIDATE_PAYMENTS_P (P_BATCH_ID IN HBG_AR_PAYMENTS_SCHEDULE.BATCH_ID%TYPE
                                ,P_STATUS OUT VARCHAR2
                                ,P_MESSAGE OUT VARCHAR2) IS

  BEGIN

    UPDATE HBG_AR_PAYMENTS_LINES HAPL
       SET RECEIPT_ID          = (SELECT CASH_RECEIPT_ID
                                    FROM AR_CASH_RECEIPTS_ALL ACRA
                                      ,  HR_OPERATING_UNITS HOU
                                   WHERE ACRA.ORG_ID         = HOU.ORGANIZATION_ID
                                     AND ACRA.RECEIPT_NUMBER = HAPL.RECEIPT_NUMBER
                                     AND HOU.NAME            = HAPL.BUSINESS_UNIT
                                    FETCH FIRST 1 ROWS ONLY)
          ,INVOICE_ID           = (SELECT CUSTOMER_TRX_ID
                                      FROM RA_CUSTOMER_TRX_ALL RCTA
                                        ,  HR_OPERATING_UNITS HOU
                                     WHERE RCTA.ORG_ID     = HOU.ORGANIZATION_ID
                                       AND RCTA.TRX_NUMBER = HAPL.INVOICE_NUMBER
                                       AND HOU.NAME        = HAPL.BUSINESS_UNIT
                                      FETCH FIRST 1 ROWS ONLY)                 
          ,LAST_UPDATE_DATE      = SYSDATE
          ,LAST_UPDATED_BY       = 'OIC_INTEGRATION'
      WHERE BATCH_ID             = NVL(P_BATCH_ID, -999)
        AND RETURN_STATUS        = 'PROCESSING'
        AND UPPER(PROCESS_TYPE)  = 'PAYMENT APPLICATION'
        AND UPPER(PAYMENT_TYPE)  = 'STANDARD';

     COMMIT;

    UPDATE HBG_AR_PAYMENTS_LINES HAPL
       SET RETURN_STATUS         = CASE WHEN (RECEIPT_ID IS NULL OR INVOICE_ID IS NULL)
                                        THEN 'ERROR'
                                        ELSE 'PROCESSING'
                                         END
          ,RETURN_MESSAGE        = CASE WHEN (RECEIPT_ID IS NULL AND INVOICE_ID IS NULL)
                                        THEN 'Error, system could not locate the Invoice number and the receipt for the '||HAPL.BUSINESS_UNIT||' Business Unit'
                                        WHEN RECEIPT_ID IS NULL 
                                        THEN 'Error, system could not locate the Receipt number for the '||HAPL.BUSINESS_UNIT||' Business Unit'
                                        WHEN INVOICE_ID IS NULL
                                        THEN 'Error, system could not locate the Invoice number for the '||HAPL.BUSINESS_UNIT||' Business Unit'
                                        ELSE NULL
                                        END                  
          ,LAST_UPDATE_DATE      = SYSDATE
          ,LAST_UPDATED_BY       = 'OIC_INTEGRATION'
      WHERE BATCH_ID             = NVL(P_BATCH_ID, -999)
        AND RETURN_STATUS        = 'PROCESSING'
        AND UPPER(PROCESS_TYPE)  = 'PAYMENT APPLICATION'
        AND UPPER(PAYMENT_TYPE)  = 'STANDARD';

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK;
         P_STATUS  := 'ERROR';
         P_MESSAGE := SQLERRM;
  END VALIDATE_PAYMENTS_P;

  PROCEDURE DELETE_PAYMENT_LINE_P ( P_BATCH_ID IN HBG_AR_PAYMENTS_LINES.BATCH_ID%TYPE
                                   ,P_LINE_ID  IN HBG_AR_PAYMENTS_LINES.LINE_ID%TYPE
                                   ,P_STATUS  OUT VARCHAR2
                                   ,P_MESSAGE OUT VARCHAR2) IS

  L_COUNT NUMBER := 0;

  BEGIN

    BEGIN
        SELECT COUNT(1)
          INTO L_COUNT
          FROM HBG_AR_PAYMENTS_LINES
         WHERE BATCH_ID      = NVL(P_BATCH_ID, -999)
           AND LINE_ID       = NVL(P_LINE_ID, -999)
           AND RETURN_STATUS = 'DRAFT';
    EXCEPTION 
        WHEN OTHERS THEN
            P_STATUS  := 'ERROR';
            P_MESSAGE := 'Error trying to validate if line is created in DRAFT, SQLERRM: '||SQLERRM;
            RAISE;
    END;

    IF L_COUNT > 0 THEN

        BEGIN
          DELETE
            FROM HBG_AR_PAYMENTS_LINES
           WHERE BATCH_ID      = NVL(P_BATCH_ID, -999)
             AND LINE_ID       = NVL(P_LINE_ID, -999)
             AND RETURN_STATUS = 'DRAFT';
             COMMIT;
             P_STATUS  := 'SUCESS';
             P_MESSAGE := 'Line deleted sucessfully.';
        EXCEPTION 
        WHEN OTHERS THEN
            P_STATUS  := 'ERROR';
            P_MESSAGE := 'Error trying to delete line, SQLERRM: '||SQLERRM;
            ROLLBACK;
            RAISE;
        END;

    ELSE
        P_STATUS  := 'ERROR';
        P_MESSAGE := 'The selected line is not created with the status as DRAFT.';
    END IF;

  END DELETE_PAYMENT_LINE_P;

END HBG_AR_PAYMENTS_PKG;

/
