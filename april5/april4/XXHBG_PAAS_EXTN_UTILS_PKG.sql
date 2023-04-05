--------------------------------------------------------
--  DDL for Package XXHBG_PAAS_EXTN_UTILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."XXHBG_PAAS_EXTN_UTILS_PKG" 
AS
    g_default_separator              CONSTANT VARCHAR2 (1) := ';';
    g_param_and_value_separator      CONSTANT VARCHAR2 (1) := '=';
    g_param_and_value_param          CONSTANT VARCHAR2 (1) := 'P';
    g_param_and_value_value          CONSTANT VARCHAR2 (1) := 'V';

    g_yes                            CONSTANT VARCHAR2 (1) := 'Y';
    g_no                             CONSTANT VARCHAR2 (1) := 'N';

    g_line_feed                      CONSTANT VARCHAR2 (1) := CHR (10);
    g_new_line                       CONSTANT VARCHAR2 (1) := CHR (13);
    g_carriage_return                CONSTANT VARCHAR2 (1) := CHR (13);
    g_crlf                           CONSTANT VARCHAR2 (2)
                                                  := g_carriage_return || g_line_feed ;
    g_tab                            CONSTANT VARCHAR2 (1) := CHR (9);
    g_ampersand                      CONSTANT VARCHAR2 (1) := CHR (38);

    g_html_entity_carriage_return    CONSTANT VARCHAR2 (5) := CHR (38) || '#13;';
    g_html_nbsp                      CONSTANT VARCHAR2 (6) := CHR (38) || 'nbsp;';

    g_exp_bind_vars                  CONSTANT VARCHAR2 (255) := ':\w+';
    g_exp_hyperlinks                 CONSTANT VARCHAR2 (255)
                                                  := '<a href="[^"]+">[^<]+</a>' ;
    g_exp_ip_addresses               CONSTANT VARCHAR2 (255) := '(\d{1,3}\.){3}\d{1,3}';
    g_exp_email_addresses            CONSTANT VARCHAR2 (255)
        := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' ;
    g_exp_email_address_list         CONSTANT VARCHAR2 (255)
        := '^((\s*[a-zA-Z0-9\._%-]+@[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,4}\s*[,;:]){1,100}?)?(\s*[a-zA-Z0-9\._%-]+@[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,4})*$' ;
    g_exp_double_words               CONSTANT VARCHAR2 (255) := ' ([A-Za-z]+) \1';
    g_exp_cc_visa                    CONSTANT VARCHAR2 (255)
                                                  := '^4[0-9]{12}(?:[0-9]{3})?$' ;
    g_exp_square_brackets            CONSTANT VARCHAR2 (255) := '\[(.*?)\]';
    g_exp_curly_brackets             CONSTANT VARCHAR2 (255) := '{(.*?)}';
    g_exp_square_or_curly_brackets   CONSTANT VARCHAR2 (255) := '\[.*?\]|\{.*?\}';

    FUNCTION csv_to_table (p_list IN VARCHAR2)
        RETURN xxhbg_varchar_tbl_type;

    FUNCTION xml_date_str_to_date (p_xml_date_str IN VARCHAR2)
        RETURN DATE;

    -- encrypt blob
    FUNCTION encrypt_aes256 (p_blob IN BLOB, p_key IN VARCHAR2)
        RETURN BLOB;

    -- decrypt blob
    FUNCTION decrypt_aes256 (p_blob IN BLOB, p_key IN VARCHAR2)
        RETURN BLOB;

    -- encode string using base64
    FUNCTION str_to_base64 (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- encode clob using base64
    FUNCTION clob_to_base64 (p_clob IN CLOB)
        RETURN CLOB;

    -- encode blob using base64
    FUNCTION blob_to_base64 (p_blob IN BLOB)
        RETURN CLOB;

    -- decode base64-encoded string
    FUNCTION base64_to_str (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- decode base64-encoded clob
    FUNCTION base64_to_clob (p_clob IN VARCHAR2)
        RETURN CLOB;

    -- decode base64-encoded clob to blob
    FUNCTION base64_to_blob (p_clob IN CLOB)
        RETURN BLOB;

    FUNCTION blob2clobbase64 (p_blob IN BLOB)
        RETURN CLOB;

    FUNCTION clobbase642blob (p_clob IN CLOB)
        RETURN BLOB;

    -- convert clob to blob
    FUNCTION clob_to_blob (p_clob IN CLOB)
        RETURN BLOB;

    -- convert blob to clob
    FUNCTION blob_to_clob (p_blob IN BLOB)
        RETURN CLOB;

    -- return string merged with substitution values
    FUNCTION get_str (p_msg      IN VARCHAR2,
                      p_value1   IN VARCHAR2 := NULL,
                      p_value2   IN VARCHAR2 := NULL,
                      p_value3   IN VARCHAR2 := NULL,
                      p_value4   IN VARCHAR2 := NULL,
                      p_value5   IN VARCHAR2 := NULL,
                      p_value6   IN VARCHAR2 := NULL,
                      p_value7   IN VARCHAR2 := NULL,
                      p_value8   IN VARCHAR2 := NULL)
        RETURN VARCHAR2;

    -- add token to string
    PROCEDURE add_token (p_text        IN OUT VARCHAR2,
                         p_token       IN     VARCHAR2,
                         p_separator   IN     VARCHAR2 := g_default_separator);

    -- get the sub-string at the Nth position
    FUNCTION get_nth_token (p_text        IN VARCHAR2,
                            p_num         IN NUMBER,
                            p_separator   IN VARCHAR2 := g_default_separator)
        RETURN VARCHAR2;

    -- get the number of sub-strings
    FUNCTION get_token_count (p_text        IN VARCHAR2,
                              p_separator   IN VARCHAR2 := g_default_separator)
        RETURN NUMBER;

    -- convert string to number
    FUNCTION str_to_num (p_str                          IN VARCHAR2,
                         p_decimal_separator            IN VARCHAR2 := NULL,
                         p_thousand_separator           IN VARCHAR2 := NULL,
                         p_raise_error_if_parse_error   IN BOOLEAN := FALSE,
                         p_value_name                   IN VARCHAR2 := NULL)
        RETURN NUMBER;

    -- copy part of string
    FUNCTION copy_str (p_string     IN VARCHAR2,
                       p_from_pos   IN NUMBER := 1,
                       p_to_pos     IN NUMBER := NULL)
        RETURN VARCHAR2;

    -- remove part of string
    FUNCTION del_str (p_string     IN VARCHAR2,
                      p_from_pos   IN NUMBER := 1,
                      p_to_pos     IN NUMBER := NULL)
        RETURN VARCHAR2;

    -- get value from parameter list with multiple named parameters
    FUNCTION get_param_value_from_list (
        p_param_name        IN VARCHAR2,
        p_param_string      IN VARCHAR2,
        p_param_separator   IN VARCHAR2 := g_default_separator,
        p_value_separator   IN VARCHAR2 := g_param_and_value_separator)
        RETURN VARCHAR2;

    -- remove all whitespace from string
    FUNCTION remove_whitespace (p_str                      IN VARCHAR2,
                                p_preserve_single_blanks   IN BOOLEAN := FALSE,
                                p_remove_line_feed         IN BOOLEAN := FALSE,
                                p_remove_tab               IN BOOLEAN := FALSE)
        RETURN VARCHAR2;

    -- remove all non-numeric characters from string
    FUNCTION remove_non_numeric_chars (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- remove all non-alpha characters (A-Z) from string
    FUNCTION remove_non_alpha_chars (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- returns true if string only contains alpha characters
    FUNCTION is_str_alpha (p_str IN VARCHAR2)
        RETURN BOOLEAN;

    -- returns true if string is alphanumeric
    FUNCTION is_str_alphanumeric (p_str IN VARCHAR2)
        RETURN BOOLEAN;

    -- returns true if string is "empty" (contains only whitespace characters)
    FUNCTION is_str_empty (p_str IN VARCHAR2)
        RETURN BOOLEAN;

    -- returns true if string is a valid number
    FUNCTION is_str_number (p_str                  IN VARCHAR2,
                            p_decimal_separator    IN VARCHAR2 := NULL,
                            p_thousand_separator   IN VARCHAR2 := NULL)
        RETURN BOOLEAN;

    -- returns true if string is an integer
    FUNCTION is_str_integer (p_str IN VARCHAR2)
        RETURN BOOLEAN;

    -- returns substring and indicates if string has been truncated
    FUNCTION short_str (p_str                    IN VARCHAR2,
                        p_length                 IN NUMBER,
                        p_truncation_indicator   IN VARCHAR2 := '...')
        RETURN VARCHAR2;

    -- return either name or value from name/value pair
    FUNCTION get_param_or_value (
        p_param_value_pair   IN VARCHAR2,
        p_param_or_value     IN VARCHAR2 := g_param_and_value_value,
        p_delimiter          IN VARCHAR2 := g_param_and_value_separator)
        RETURN VARCHAR2;

    -- add item to delimited list
    FUNCTION add_item_to_list (p_item        IN VARCHAR2,
                               p_list        IN VARCHAR2,
                               p_separator   IN VARCHAR2 := g_default_separator)
        RETURN VARCHAR2;

    -- convert string to boolean
    FUNCTION str_to_bool (p_str IN VARCHAR2)
        RETURN BOOLEAN;

    -- convert string to boolean string
    FUNCTION str_to_bool_str (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- get pretty string
    FUNCTION get_pretty_str (p_str IN VARCHAR2)
        RETURN VARCHAR2;

    -- parse string to date, accept various formats
    FUNCTION parse_date (p_str IN VARCHAR2)
        RETURN DATE;

    -- split delimited string to rows
    FUNCTION split_str (p_str IN VARCHAR2, p_delim IN VARCHAR2:= g_default_separator)
        RETURN xxhbg_varchar_tbl_type
        PIPELINED;

    -- returns true if value is valid email address
    FUNCTION is_valid_email (p_value IN VARCHAR2)
        RETURN BOOLEAN;

    -- returns true if value is valid email address list
    FUNCTION is_valid_email_list (p_value IN VARCHAR2)
        RETURN BOOLEAN;
END XXHBG_PAAS_EXTN_UTILS_PKG;


/
