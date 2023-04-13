--------------------------------------------------------
--  DDL for Procedure HBG_TEST_TITLE_RIGHTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "HBG_INTEGRATION"."HBG_TEST_TITLE_RIGHTS" 
is

TYPE l_array IS TABLE OF hbg_title_right_details_stg%ROWTYPE;
l_data l_array;

CURSOR c IS SELECT
    tm_sr_uid,
    isbn,
    regexp_substr(non_exclusive_category, '[^;]+', 1, level) country_code,
    'NON_EXCLUSIVE'                                          category,
    active_indicator,
    transaction_user,
    transaction_date,
    last_upd_user,
    last_upd_date,
    '' status
FROM
    hbg_title_rights_stg
WHERE
    non_exclusive_category IS NOT NULL
    and rownum <= 10
CONNECT BY
    regexp_substr(non_exclusive_category, '[^;]+', 1, level) IS NOT NULL

;

BEGIN
    OPEN c;
    LOOP
    FETCH c BULK COLLECT INTO l_data;

    FORALL i IN 1..l_data.COUNT
    INSERT INTO hbg_title_right_details_stg VALUES l_data(i);

    EXIT WHEN c%NOTFOUND;
    END LOOP;
    CLOSE c;
END hbg_test_title_rights;

/
