--------------------------------------------------------
--  DDL for Package Body XXHBG_PAAS_EXTN_UTILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."XXHBG_PAAS_EXTN_UTILS_PKG" 
AS
    g_encryption_type_aes   CONSTANT PLS_INTEGER
        := DBMS_CRYPTO.encrypt_aes256 + DBMS_CRYPTO.chain_cbc + DBMS_CRYPTO.pad_pkcs5 ;

    m_nls_decimal_separator          VARCHAR2 (1);

    FUNCTION csv_to_table (p_list IN VARCHAR2)
        RETURN xxhbg_varchar_tbl_type
    AS
        l_string        VARCHAR2 (32767) := p_list || ',';
        l_comma_index   PLS_INTEGER;
        l_index         PLS_INTEGER := 1;
        l_tab           xxhbg_varchar_tbl_type := xxhbg_varchar_tbl_type ();
    BEGIN
        LOOP
            l_comma_index := INSTR (l_string, ',', l_index);
            EXIT WHEN l_comma_index = 0;
            l_tab.EXTEND;
            l_tab (l_tab.COUNT) :=
                TRIM (SUBSTR (l_string, l_index, l_comma_index - l_index));
            l_index := l_comma_index + 1;
        END LOOP;

        RETURN l_tab;
    END csv_to_table;


    FUNCTION xml_date_str_to_date (p_xml_date_str IN VARCHAR2)
        RETURN DATE
    IS
        l_date   DATE := NULL;
    BEGIN
        SELECT TO_DATE (
                   TO_CHAR (
                       TO_TIMESTAMP_TZ (p_xml_date_str,
                                        'YYYY-MM-DD"T"HH24:MI:SS.FF9tzh:tzm'),
                       'DD-MON-YYYY HH:MI:SS AM'),
                   'DD-MON-YYYY HH:MI:SS AM')
          INTO l_date
          FROM DUAL;

        RETURN l_date;
    END xml_date_str_to_date;



    FUNCTION encrypt_aes256 (p_blob IN BLOB, p_key IN VARCHAR2)
        RETURN BLOB
    AS
        l_key_raw       RAW (32);
        l_returnvalue   BLOB;
    BEGIN
        l_key_raw := UTL_RAW.cast_to_raw (p_key);

        DBMS_LOB.createtemporary (l_returnvalue, FALSE);

        DBMS_CRYPTO.encrypt (l_returnvalue,
                             p_blob,
                             g_encryption_type_aes,
                             l_key_raw);

        RETURN l_returnvalue;
    END encrypt_aes256;

    FUNCTION decrypt_aes256 (p_blob IN BLOB, p_key IN VARCHAR2)
        RETURN BLOB
    AS
        l_key_raw       RAW (32);
        l_returnvalue   BLOB;
    BEGIN
        l_key_raw := UTL_RAW.cast_to_raw (p_key);

        DBMS_LOB.createtemporary (l_returnvalue, FALSE);

        DBMS_CRYPTO.decrypt (l_returnvalue,
                             p_blob,
                             g_encryption_type_aes,
                             l_key_raw);

        RETURN l_returnvalue;
    END decrypt_aes256;

    FUNCTION str_to_base64 (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN


        l_returnvalue :=
            UTL_RAW.cast_to_varchar2 (
                UTL_ENCODE.base64_encode (UTL_RAW.cast_to_raw (p_str)));

        RETURN l_returnvalue;
    END str_to_base64;


    FUNCTION clob_to_base64 (p_clob IN CLOB)
        RETURN CLOB
    AS
            --The chunk size must be a multiple of 48
       CHUNKSIZE INTEGER := 576;
       PLACE   INTEGER := 1;
       FILE_SIZE INTEGER;
       TEMP_CHUNK VARCHAR(4000);
       OUT_CLOB  CLOB;
BEGIN
       FILE_SIZE := LENGTH(p_clob);
       WHILE (PLACE <= FILE_SIZE)
       LOOP
              TEMP_CHUNK := SUBSTR(p_clob, PLACE, CHUNKSIZE);
              OUT_CLOB := OUT_CLOB 
              || UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(TEMP_CHUNK)));
              PLACE := PLACE + CHUNKSIZE;
       END LOOP;
       RETURN OUT_CLOB;
    END clob_to_base64;


    FUNCTION blob_to_base64 (p_blob IN BLOB)
        RETURN CLOB
    AS
        l_pos           PLS_INTEGER := 1;
        l_buffer        VARCHAR2 (32767);
        l_lob_len       INTEGER := DBMS_LOB.getlength (p_blob);
        l_width         PLS_INTEGER := (76 / 4 * 3) - 9;
        l_returnvalue   CLOB;
    BEGIN


        DBMS_LOB.createtemporary (l_returnvalue, TRUE);
        DBMS_LOB.open (l_returnvalue, DBMS_LOB.lob_readwrite);

        WHILE (l_pos < l_lob_len)
        LOOP
            l_buffer :=
                UTL_RAW.cast_to_varchar2 (
                    UTL_ENCODE.base64_encode (DBMS_LOB.SUBSTR (p_blob, l_width, l_pos)));
            DBMS_LOB.writeappend (l_returnvalue, LENGTH (l_buffer), l_buffer);
            l_pos := l_pos + l_width;
        END LOOP;

        RETURN l_returnvalue;
    END blob_to_base64;


    FUNCTION base64_to_str (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN


        l_returnvalue :=
            UTL_RAW.cast_to_varchar2 (
                UTL_ENCODE.base64_decode (UTL_RAW.cast_to_raw (p_str)));

        RETURN l_returnvalue;
    END base64_to_str;


    FUNCTION base64_to_clob (p_clob IN VARCHAR2)
        RETURN CLOB
    AS
        l_pos           PLS_INTEGER := 1;
        l_buffer        RAW (36);
        l_buffer_str    VARCHAR2 (2000);
        l_lob_len       INTEGER := DBMS_LOB.getlength (p_clob);
        l_width         PLS_INTEGER := (76 / 4 * 3) - 9;
        l_returnvalue   CLOB;
    BEGIN


        IF p_clob IS NOT NULL
        THEN
            DBMS_LOB.createtemporary (l_returnvalue, TRUE);
            DBMS_LOB.open (l_returnvalue, DBMS_LOB.lob_readwrite);

            WHILE (l_pos < l_lob_len)
            LOOP
                l_buffer :=
                    UTL_ENCODE.base64_decode (
                        UTL_RAW.cast_to_raw (DBMS_LOB.SUBSTR (p_clob, l_width, l_pos)));
                l_buffer_str := UTL_RAW.cast_to_varchar2 (l_buffer);
                DBMS_LOB.writeappend (l_returnvalue, LENGTH (l_buffer_str), l_buffer_str);
                l_pos := l_pos + l_width;
            END LOOP;
        END IF;

        RETURN l_returnvalue;
    END base64_to_clob;


    FUNCTION base64_to_blob (p_clob IN CLOB)
        RETURN BLOB
    AS
        l_pos           PLS_INTEGER := 1;
        l_buffer        RAW (36);
        l_lob_len       INTEGER := DBMS_LOB.getlength (p_clob);
        l_width         PLS_INTEGER := (76 / 4 * 3) - 9;
        l_returnvalue   BLOB;
    BEGIN
        /*

        Purpose:      decode base64-encoded clob to blob

        Remarks:      based on Jason Straub's clobbase642blob in package flex_ws_api (aka apex_web_service)
         */

        DBMS_LOB.createtemporary (l_returnvalue, TRUE);
        DBMS_LOB.open (l_returnvalue, DBMS_LOB.lob_readwrite);

        WHILE (l_pos < l_lob_len)
        LOOP
            l_buffer :=
                UTL_ENCODE.base64_decode (
                    UTL_RAW.cast_to_raw (DBMS_LOB.SUBSTR (p_clob, l_width, l_pos)));
            DBMS_LOB.writeappend (l_returnvalue, UTL_RAW.LENGTH (l_buffer), l_buffer);
            l_pos := l_pos + l_width;
        END LOOP;

        RETURN l_returnvalue;
    END base64_to_blob;

    FUNCTION blob2clobbase64 (p_blob IN BLOB)
        RETURN CLOB
    IS
        pos       PLS_INTEGER := 1;
        buffer    VARCHAR2 (32767);
        res       CLOB;
        lob_len   INTEGER := DBMS_LOB.getlength (p_blob);
        l_width   PLS_INTEGER := (76 / 4 * 3) - 9;
    BEGIN
        DBMS_LOB.createtemporary (res, TRUE);
        DBMS_LOB.open (res, DBMS_LOB.lob_readwrite);

        WHILE (pos < lob_len)
        LOOP
            buffer :=
                UTL_RAW.cast_to_varchar2 (
                    UTL_ENCODE.base64_encode (DBMS_LOB.SUBSTR (p_blob, l_width, pos)));

            DBMS_LOB.writeappend (res, LENGTH (buffer), buffer);

            pos := pos + l_width;
        END LOOP;

        RETURN res;
    END blob2clobbase64;

    FUNCTION clobbase642blob (p_clob IN CLOB)
        RETURN BLOB
    IS
        pos       PLS_INTEGER := 1;
        buffer    RAW (36);
        res       BLOB;
        lob_len   INTEGER := DBMS_LOB.getlength (p_clob);
        l_width   PLS_INTEGER := (76 / 4 * 3) - 9;
    BEGIN
        DBMS_LOB.createtemporary (res, TRUE);
        DBMS_LOB.open (res, DBMS_LOB.lob_readwrite);

        WHILE (pos < lob_len)
        LOOP
            buffer :=
                UTL_ENCODE.base64_decode (
                    UTL_RAW.cast_to_raw (DBMS_LOB.SUBSTR (p_clob, l_width, pos)));

            DBMS_LOB.writeappend (res, UTL_RAW.LENGTH (buffer), buffer);

            pos := pos + l_width;
        END LOOP;

        RETURN res;
    END clobbase642blob;

    FUNCTION clob_to_blob (p_clob IN CLOB)
        RETURN BLOB
    AS
        l_returnvalue     BLOB;
        l_dest_offset     INTEGER := 1;
        l_source_offset   INTEGER := 1;
        l_lang_context    INTEGER := DBMS_LOB.default_lang_ctx;
        l_warning         INTEGER := DBMS_LOB.warn_inconvertible_char;
    BEGIN

        DBMS_LOB.createtemporary (l_returnvalue, TRUE);

        DBMS_LOB.converttoblob (dest_lob       => l_returnvalue,
                                src_clob       => p_clob,
                                amount         => DBMS_LOB.getlength (p_clob),
                                dest_offset    => l_dest_offset,
                                src_offset     => l_source_offset,
                                blob_csid      => DBMS_LOB.default_csid,
                                lang_context   => l_lang_context,
                                warning        => l_warning);

        RETURN l_returnvalue;
    END clob_to_blob;


    FUNCTION blob_to_clob (p_blob IN BLOB)
        RETURN CLOB
    AS
        l_returnvalue     CLOB;
        l_dest_offset     INTEGER := 1;
        l_source_offset   INTEGER := 1;
        l_lang_context    INTEGER := DBMS_LOB.default_lang_ctx;
        l_warning         INTEGER := DBMS_LOB.warn_inconvertible_char;
    BEGIN


        DBMS_LOB.createtemporary (l_returnvalue, TRUE);

        DBMS_LOB.converttoclob (dest_lob       => l_returnvalue,
                                src_blob       => p_blob,
                                amount         => DBMS_LOB.lobmaxsize,
                                dest_offset    => l_dest_offset,
                                src_offset     => l_source_offset,
                                blob_csid      => DBMS_LOB.default_csid,
                                lang_context   => l_lang_context,
                                warning        => l_warning);

        RETURN l_returnvalue;
    END blob_to_clob;

    PROCEDURE add_token (p_text        IN OUT VARCHAR2,
                         p_token       IN     VARCHAR2,
                         p_separator   IN     VARCHAR2 := g_default_separator)
    AS
    BEGIN


        IF p_text IS NULL
        THEN
            p_text := p_token;
        ELSE
            p_text := p_text || p_separator || p_token;
        END IF;
    END add_token;


    FUNCTION get_nth_token (p_text        IN VARCHAR2,
                            p_num         IN NUMBER,
                            p_separator   IN VARCHAR2 := g_default_separator)
        RETURN VARCHAR2
    AS
        l_pos_begin     PLS_INTEGER;
        l_pos_end       PLS_INTEGER;
        l_returnvalue   VARCHAR2 (32767);
    BEGIN


        IF p_num <= 0
        THEN
            RETURN NULL;
        ELSIF p_num = 1
        THEN
            l_pos_begin := 1;
        ELSE
            l_pos_begin :=
                INSTR (p_text,
                       p_separator,
                       1,
                       p_num - 1);
        END IF;

        -- separator may be the first character

        l_pos_end :=
            INSTR (p_text,
                   p_separator,
                   1,
                   p_num);

        IF l_pos_end > 1
        THEN
            l_pos_end := l_pos_end - 1;
        END IF;

        IF l_pos_begin > 0
        THEN
            -- find the last element even though it may not be terminated by separator
            IF l_pos_end <= 0
            THEN
                l_pos_end := LENGTH (p_text);
            END IF;

            -- do not include separator character in output
            IF p_num = 1
            THEN
                l_returnvalue :=
                    SUBSTR (p_text, l_pos_begin, l_pos_end - l_pos_begin + 1);
            ELSE
                l_returnvalue :=
                    SUBSTR (p_text, l_pos_begin + 1, l_pos_end - l_pos_begin);
            END IF;
        ELSE
            l_returnvalue := NULL;
        END IF;

        RETURN l_returnvalue;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_nth_token;


    FUNCTION get_token_count (p_text        IN VARCHAR2,
                              p_separator   IN VARCHAR2 := g_default_separator)
        RETURN NUMBER
    AS
        l_pos           PLS_INTEGER;
        l_counter       PLS_INTEGER := 0;
        l_returnvalue   NUMBER;
    BEGIN



        IF p_text IS NULL
        THEN
            l_returnvalue := 0;
        ELSE
            LOOP
                l_pos :=
                    INSTR (p_text,
                           p_separator,
                           1,
                           l_counter + 1);

                IF l_pos > 0
                THEN
                    l_counter := l_counter + 1;
                ELSE
                    EXIT;
                END IF;
            END LOOP;

            l_returnvalue := l_counter + 1;
        END IF;

        RETURN l_returnvalue;
    END get_token_count;

    FUNCTION get_nls_decimal_separator
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (1);
    BEGIN


        IF m_nls_decimal_separator IS NULL
        THEN
            BEGIN
                SELECT SUBSTR (VALUE, 1, 1)
                  INTO l_returnvalue
                  FROM nls_session_parameters
                 WHERE parameter = 'NLS_NUMERIC_CHARACTERS';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_returnvalue := '.';
            END;

            m_nls_decimal_separator := l_returnvalue;
        END IF;

        l_returnvalue := m_nls_decimal_separator;

        RETURN l_returnvalue;
    END get_nls_decimal_separator;

    FUNCTION get_str (p_msg      IN VARCHAR2,
                      p_value1   IN VARCHAR2 := NULL,
                      p_value2   IN VARCHAR2 := NULL,
                      p_value3   IN VARCHAR2 := NULL,
                      p_value4   IN VARCHAR2 := NULL,
                      p_value5   IN VARCHAR2 := NULL,
                      p_value6   IN VARCHAR2 := NULL,
                      p_value7   IN VARCHAR2 := NULL,
                      p_value8   IN VARCHAR2 := NULL)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN


        l_returnvalue := p_msg;

        l_returnvalue := REPLACE (l_returnvalue, '%1', NVL (p_value1, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%2', NVL (p_value2, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%3', NVL (p_value3, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%4', NVL (p_value4, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%5', NVL (p_value5, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%6', NVL (p_value6, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%7', NVL (p_value7, '(blank)'));
        l_returnvalue := REPLACE (l_returnvalue, '%8', NVL (p_value8, '(blank)'));

        RETURN l_returnvalue;
    END get_str;

    FUNCTION str_to_num (p_str                          IN VARCHAR2,
                         p_decimal_separator            IN VARCHAR2 := NULL,
                         p_thousand_separator           IN VARCHAR2 := NULL,
                         p_raise_error_if_parse_error   IN BOOLEAN := FALSE,
                         p_value_name                   IN VARCHAR2 := NULL)
        RETURN NUMBER
    AS
        l_returnvalue   NUMBER;
    BEGIN


        BEGIN
            IF (p_decimal_separator IS NULL) AND (p_thousand_separator IS NULL)
            THEN
                l_returnvalue := TO_NUMBER (p_str);
            ELSE
                l_returnvalue :=
                    TO_NUMBER (
                        REPLACE (REPLACE (p_str, p_thousand_separator, ''),
                                 p_decimal_separator,
                                 get_nls_decimal_separator));
            END IF;
        EXCEPTION
            WHEN VALUE_ERROR
            THEN
                IF p_raise_error_if_parse_error
                THEN
                    raise_application_error (
                        -20000,
                        get_str (
                               'Failed to parse the string "%1" to a valid number. Using decimal separator = "%2" and thousand separator = "%3". Field name = "%4". '
                            || SQLERRM,
                            p_str,
                            p_decimal_separator,
                            p_thousand_separator,
                            p_value_name));
                ELSE
                    l_returnvalue := NULL;
                END IF;
        END;

        RETURN l_returnvalue;
    END str_to_num;


    FUNCTION copy_str (p_string     IN VARCHAR2,
                       p_from_pos   IN NUMBER := 1,
                       p_to_pos     IN NUMBER := NULL)
        RETURN VARCHAR2
    AS
        l_to_pos        PLS_INTEGER;
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    copy part of string

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     08.05.2007  Created

        */

        IF (p_string IS NULL) OR (p_from_pos <= 0)
        THEN
            l_returnvalue := NULL;
        ELSE
            IF p_to_pos IS NULL
            THEN
                l_to_pos := LENGTH (p_string);
            ELSE
                l_to_pos := p_to_pos;
            END IF;

            IF l_to_pos > LENGTH (p_string)
            THEN
                l_to_pos := LENGTH (p_string);
            END IF;

            l_returnvalue := SUBSTR (p_string, p_from_pos, l_to_pos - p_from_pos + 1);
        END IF;

        RETURN l_returnvalue;
    END copy_str;


    FUNCTION del_str (p_string     IN VARCHAR2,
                      p_from_pos   IN NUMBER := 1,
                      p_to_pos     IN NUMBER := NULL)
        RETURN VARCHAR2
    AS
        l_to_pos        PLS_INTEGER;
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    remove part of string

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     08.05.2007  Created

        */

        IF (p_string IS NULL) OR (p_from_pos <= 0)
        THEN
            l_returnvalue := NULL;
        ELSE
            IF p_to_pos IS NULL
            THEN
                l_to_pos := LENGTH (p_string);
            ELSE
                l_to_pos := p_to_pos;
            END IF;

            IF l_to_pos > LENGTH (p_string)
            THEN
                l_to_pos := LENGTH (p_string);
            END IF;

            l_returnvalue :=
                   SUBSTR (p_string, 1, p_from_pos - 1)
                || SUBSTR (p_string, l_to_pos + 1, LENGTH (p_string) - l_to_pos);
        END IF;

        RETURN l_returnvalue;
    END del_str;


    FUNCTION get_param_value_from_list (
        p_param_name        IN VARCHAR2,
        p_param_string      IN VARCHAR2,
        p_param_separator   IN VARCHAR2 := g_default_separator,
        p_value_separator   IN VARCHAR2 := g_param_and_value_separator)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
        l_temp_str      VARCHAR2 (32767);
        l_begin_pos     PLS_INTEGER;
        l_end_pos       PLS_INTEGER;
    BEGIN
        /*

        Purpose:    get value from parameter list with multiple named parameters

        Remarks:    given a string of type param1=value1;param2=value2;param3=value3,
                    extract the value part of the given param (specified by name)

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     16.05.2007  Created
        MBR     24.09.2015  If parameter name not specified (null), then return null

        */

        IF p_param_name IS NOT NULL
        THEN
            -- get the starting position of the param name
            l_begin_pos := INSTR (p_param_string, p_param_name || p_value_separator);

            IF l_begin_pos = 0
            THEN
                l_returnvalue := NULL;
            ELSE
                -- trim off characters before param value begins, including param name
                l_temp_str :=
                    SUBSTR (p_param_string,
                            l_begin_pos,
                            LENGTH (p_param_string) - l_begin_pos + 1);
                l_temp_str :=
                    del_str (l_temp_str, 1, LENGTH (p_param_name || p_value_separator));

                -- now find the first next occurence of the character delimiting the params
                -- if delimiter not found, return the rest of the string

                l_end_pos := INSTR (l_temp_str, p_param_separator);

                IF l_end_pos = 0
                THEN
                    l_end_pos := LENGTH (l_temp_str);
                ELSE
                    -- strip off delimiter
                    l_end_pos := l_end_pos - 1;
                END IF;

                -- retrieve the value
                l_returnvalue := copy_str (l_temp_str, 1, l_end_pos);
            END IF;
        END IF;

        RETURN l_returnvalue;
    END get_param_value_from_list;


    FUNCTION remove_whitespace (p_str                      IN VARCHAR2,
                                p_preserve_single_blanks   IN BOOLEAN := FALSE,
                                p_remove_line_feed         IN BOOLEAN := FALSE,
                                p_remove_tab               IN BOOLEAN := FALSE)
        RETURN VARCHAR2
    AS
        l_temp_char   CONSTANT VARCHAR2 (1) := CHR (0);
        l_returnvalue          VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    remove all whitespace from string

        Remarks:    for preserving single blanks, see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:13912710295209

                    "I found this solution (...) to be really "elegant" (not to mention terse, fast, and 99.9999% complete --
                     normally, chr(0) will fill the bill as a "safe character"."

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     08.06.2007  Created
        MBR     13.01.2011  Added option to remove tab characters

        */

        IF p_preserve_single_blanks
        THEN
            l_returnvalue :=
                TRIM (
                    REPLACE (
                        REPLACE (REPLACE (p_str, ' ', ' ' || l_temp_char),
                                 l_temp_char || ' ',
                                 ''),
                        ' ' || l_temp_char,
                        ' '));
        ELSE
            l_returnvalue := REPLACE (p_str, ' ', '');
        END IF;

        IF p_remove_line_feed
        THEN
            l_returnvalue := REPLACE (l_returnvalue, g_line_feed, '');
            l_returnvalue := REPLACE (l_returnvalue, g_carriage_return, '');
        END IF;

        IF p_remove_tab
        THEN
            l_returnvalue := REPLACE (l_returnvalue, g_tab, '');
        END IF;

        RETURN l_returnvalue;
    END remove_whitespace;


    FUNCTION remove_non_numeric_chars (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    remove all non-numeric characters from string

        Remarks:    leaving thousand and decimal separator values (perhaps the actual values used could have been passed as parameters)

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     14.06.2007  Created

        */

        l_returnvalue := REGEXP_REPLACE (p_str, '[^0-9,.]', '');

        RETURN l_returnvalue;
    END remove_non_numeric_chars;


    FUNCTION remove_non_alpha_chars (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    remove all non-alpha characters (A-Z) from string

        Remarks:    does not support non-English characters (but the regular expression could be modified to support it)

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     04.07.2007  Created

        */

        l_returnvalue := REGEXP_REPLACE (p_str, '[^A-Za-z]', '');

        RETURN l_returnvalue;
    END remove_non_alpha_chars;


    FUNCTION is_str_alpha (p_str IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:    returns true if string only contains alpha characters

        Who     Date        Description
        ------  ----------  -------------------------------------
        MJH     12.05.2015  Created

        */

        l_returnvalue := REGEXP_INSTR (p_str, '[^a-z|A-Z]') = 0;

        RETURN l_returnvalue;
    END is_str_alpha;


    FUNCTION is_str_alphanumeric (p_str IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:    returns true if string is alphanumeric

        Who     Date        Description
        ------  ----------  -------------------------------------
        MJH     12.05.2015  Created

        */

        l_returnvalue := REGEXP_INSTR (p_str, '[^a-z|A-Z|0-9]') = 0;

        RETURN l_returnvalue;
    END is_str_alphanumeric;


    FUNCTION is_str_empty (p_str IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:    returns true if string is "empty" (contains only whitespace characters)

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     14.06.2007  Created

        */

        IF p_str IS NULL
        THEN
            l_returnvalue := TRUE;
        ELSIF remove_whitespace (p_str, FALSE, TRUE) = ''
        THEN
            l_returnvalue := TRUE;
        ELSE
            l_returnvalue := FALSE;
        END IF;

        RETURN l_returnvalue;
    END is_str_empty;


    FUNCTION is_str_number (p_str                  IN VARCHAR2,
                            p_decimal_separator    IN VARCHAR2 := NULL,
                            p_thousand_separator   IN VARCHAR2 := NULL)
        RETURN BOOLEAN
    AS
        l_number        NUMBER;
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:    returns true if string is a valid number

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     04.07.2007  Created

        */

        BEGIN
            IF (p_decimal_separator IS NULL) AND (p_thousand_separator IS NULL)
            THEN
                l_number := TO_NUMBER (p_str);
            ELSE
                l_number :=
                    TO_NUMBER (
                        REPLACE (REPLACE (p_str, p_thousand_separator, ''),
                                 p_decimal_separator,
                                 get_nls_decimal_separator));
            END IF;

            l_returnvalue := TRUE;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_returnvalue := FALSE;
        END;

        RETURN l_returnvalue;
    END is_str_number;


    FUNCTION is_str_integer (p_str IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:    returns true if string is an integer

        Who     Date        Description
        ------  ----------  -------------------------------------
        MJH     12.05.2015  Created

        */

        l_returnvalue := REGEXP_INSTR (p_str, '[^0-9]') = 0;

        RETURN l_returnvalue;
    END is_str_integer;


    FUNCTION short_str (p_str                    IN VARCHAR2,
                        p_length                 IN NUMBER,
                        p_truncation_indicator   IN VARCHAR2 := '...')
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    returns substring and indicates if string has been truncated

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     04.07.2007  Created

        */

        IF LENGTH (p_str) > p_length
        THEN
            l_returnvalue :=
                   SUBSTR (p_str, 1, p_length - LENGTH (p_truncation_indicator))
                || p_truncation_indicator;
        ELSE
            l_returnvalue := p_str;
        END IF;

        RETURN l_returnvalue;
    END short_str;


    FUNCTION get_param_or_value (
        p_param_value_pair   IN VARCHAR2,
        p_param_or_value     IN VARCHAR2 := g_param_and_value_value,
        p_delimiter          IN VARCHAR2 := g_param_and_value_separator)
        RETURN VARCHAR2
    AS
        l_delim_pos     PLS_INTEGER;
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    return either name or value from name/value pair

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     18.08.2009  Created

        */

        l_delim_pos := INSTR (p_param_value_pair, p_delimiter);

        IF l_delim_pos != 0
        THEN
            IF UPPER (p_param_or_value) = g_param_and_value_value
            THEN
                l_returnvalue :=
                    SUBSTR (p_param_value_pair,
                            l_delim_pos + 1,
                            LENGTH (p_param_value_pair) - l_delim_pos);
            ELSIF UPPER (p_param_or_value) = g_param_and_value_param
            THEN
                l_returnvalue := SUBSTR (p_param_value_pair, 1, l_delim_pos - 1);
            END IF;
        END IF;

        RETURN l_returnvalue;
    END get_param_or_value;


    FUNCTION add_item_to_list (p_item        IN VARCHAR2,
                               p_list        IN VARCHAR2,
                               p_separator   IN VARCHAR2 := g_default_separator)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    add item to list

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     15.12.2008  Created

        */

        IF p_list IS NULL
        THEN
            l_returnvalue := p_item;
        ELSE
            l_returnvalue := p_list || p_separator || p_item;
        END IF;

        RETURN l_returnvalue;
    END add_item_to_list;


    FUNCTION str_to_bool (p_str IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN := FALSE;
    BEGIN
        /*

        Purpose:    convert string to boolean

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     06.01.2009  Created

        */

        IF LOWER (p_str) IN ('y',
                             'yes',
                             'true',
                             '1')
        THEN
            l_returnvalue := TRUE;
        END IF;

        RETURN l_returnvalue;
    END str_to_bool;


    FUNCTION str_to_bool_str (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (1) := g_no;
    BEGIN
        /*

        Purpose:    convert string to (application-defined) boolean string

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     06.01.2009  Created
        MJH     12.05.2015  Leverage string_util_pkg.str_to_bool in order to reduce code redundancy

        */

        IF str_to_bool (p_str)
        THEN
            l_returnvalue := g_yes;
        END IF;

        RETURN l_returnvalue;
    END str_to_bool_str;


    FUNCTION get_pretty_str (p_str IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    returns "pretty" string

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     16.11.2009  Created

        */

        l_returnvalue := REPLACE (INITCAP (TRIM (p_str)), '_', ' ');

        RETURN l_returnvalue;
    END get_pretty_str;


    FUNCTION parse_date (p_str IN VARCHAR2)
        RETURN DATE
    AS
        l_returnvalue   DATE;

        FUNCTION try_parse_date (p_str IN VARCHAR2, p_date_format IN VARCHAR2)
            RETURN DATE
        AS
            l_returnvalue   DATE;
        BEGIN
            BEGIN
                l_returnvalue := TO_DATE (p_str, p_date_format);
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_returnvalue := NULL;
            END;

            RETURN l_returnvalue;
        END try_parse_date;
    BEGIN
        /*

        Purpose:    parse string to date, accept various formats

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     16.11.2009  Created

        */

        -- note: Oracle handles separator characters (comma, dash, slash) interchangeably,
        --       so we don't need to duplicate the various format masks with different separators (slash, hyphen)

        l_returnvalue := try_parse_date (p_str, 'DD.MM.RRRR HH24:MI:SS');
        l_returnvalue :=
            COALESCE (l_returnvalue, try_parse_date (p_str, 'DD.MM HH24:MI:SS'));
        l_returnvalue :=
            COALESCE (l_returnvalue, try_parse_date (p_str, 'DDMMYYYY HH24:MI:SS'));
        l_returnvalue :=
            COALESCE (l_returnvalue, try_parse_date (p_str, 'DDMMRRRR HH24:MI:SS'));
        l_returnvalue :=
            COALESCE (l_returnvalue, try_parse_date (p_str, 'YYYY.MM.DD HH24:MI:SS'));
        l_returnvalue := COALESCE (l_returnvalue, try_parse_date (p_str, 'MM.YYYY'));
        l_returnvalue :=
            COALESCE (l_returnvalue, try_parse_date (p_str, 'DD.MON.RRRR HH24:MI:SS'));
        l_returnvalue :=
            COALESCE (l_returnvalue,
                      try_parse_date (p_str, 'YYYY-MM-DD"T"HH24:MI:SS".000Z"')); -- standard XML date format

        RETURN l_returnvalue;
    END parse_date;


    FUNCTION split_str (p_str IN VARCHAR2, p_delim IN VARCHAR2:= g_default_separator)
        RETURN xxhbg_varchar_tbl_type
        PIPELINED
    AS
        l_str   LONG := p_str || p_delim;
        l_n     NUMBER;
    BEGIN
        /*

        Purpose:    split delimited string to rows

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     23.11.2009  Created

        */

        LOOP
            l_n := INSTR (l_str, p_delim);
            EXIT WHEN (NVL (l_n, 0) = 0);
            PIPE ROW (LTRIM (RTRIM (SUBSTR (l_str, 1, l_n - 1))));
            l_str := SUBSTR (l_str, l_n + 1);
        END LOOP;

        RETURN;
    END split_str;


    FUNCTION join_str (p_cursor   IN SYS_REFCURSOR,
                       p_delim    IN VARCHAR2 := g_default_separator)
        RETURN VARCHAR2
    AS
        l_value         VARCHAR2 (32767);
        l_returnvalue   VARCHAR2 (32767);
    BEGIN
        /*

        Purpose:    create delimited string from cursor

        Remarks:

        Who     Date        Description
        ------  ----------  -------------------------------------
        MBR     23.11.2009  Created

        */

        LOOP
            FETCH p_cursor INTO l_value;

            EXIT WHEN p_cursor%NOTFOUND;

            IF l_returnvalue IS NOT NULL
            THEN
                l_returnvalue := l_returnvalue || p_delim;
            END IF;

            l_returnvalue := l_returnvalue || l_value;
        END LOOP;

        RETURN l_returnvalue;
    END join_str;

    FUNCTION is_valid_email (p_value IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_value         VARCHAR2 (32000);
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:      returns true if value is valid email address

        Remarks:

        Who     Date        Description
        ------  ----------  --------------------------------
        MBR     23.10.2011  Created
        Tim N   01.04.2016  Enhancements

        */

        l_returnvalue := REGEXP_LIKE (p_value, g_exp_email_addresses);

        RETURN l_returnvalue;
    END is_valid_email;


    FUNCTION is_valid_email_list (p_value IN VARCHAR2)
        RETURN BOOLEAN
    AS
        l_returnvalue   BOOLEAN;
    BEGIN
        /*

        Purpose:      returns true if value is valid email address list

        Remarks:      see http://application-express-blog.e-dba.com/?p=158 for the regular expression used

        Who     Date        Description
        ------  ----------  --------------------------------
        MBR     23.10.2011  Created
        Tim N   01.04.2016  Enhancements

        */

        l_returnvalue := REGEXP_LIKE (p_value, g_exp_email_address_list);

        RETURN l_returnvalue;
    END is_valid_email_list;
END xxhbg_paas_extn_utils_pkg;


/
