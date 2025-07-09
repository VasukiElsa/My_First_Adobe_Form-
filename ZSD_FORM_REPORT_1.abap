*&---------------------------------------------------------------------*
*& Report ZSD_FORM_REPORT_1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_form_report_1.

**Declaring Structure to hold Header-level-data FROM VBAK and custom Table.
*TYPES: BEGIN OF ty_data,
*         vbeln          TYPE  vbak-vbeln,
*         kunnr          TYPE vbak-kunnr,
*         erdat          TYPE vbak-erdat,
*         name1          TYPE kna1-name1,
**       DEL_DATE TYPE SY-DATUM,
*         receipt_number TYPE ztask_abapt-receipt_number,
*         cheque_no      TYPE ztask_abapt-cheque_no,
*         bank           TYPE ztask_abapt-bank,
*         receipt_amt    TYPE ztask_abapt-receipt_amt,
*       END OF TY_dATA.
*
**Declaring Structure to hold Item-level-data FROM VBAP.
*TYPES : BEGIN OF ty_item,
*          matnr TYPE vbap-matnr,
*          arktx TYPE vbap-arktx,
*          zmeng TYPE vbap-zmeng,
*          zieme TYPE vbap-zieme,
*        END OF ty_item.

*Here we are declaring internal table for item-level data.Because Each Sales order can have multiple items.
*Workarea for Header-level data. Because used to hold a single row.


DATA: it_item TYPE TABLE OF ZSD_ITEM,
      wa_data TYPE ZSD_DATA.

DATA: lv_logo TYPE xstring.

DATA:
    ls_outputparams TYPE sfpoutputparams,
    lv_fm_name      TYPE rs38l_fnam,
    ls_pdf_file     TYPE fpformoutput.


CONSTANTS : lv_header_logo TYPE tdobname VALUE 'ZSAPLOGO',
            c_ID           TYPE tdidgr VALUE 'BMAP',
            c_BTYPE        TYPE tdbtype VALUE 'BCOL',
            c_OBJECT       TYPE tdobjectgr VALUE 'GRAPHICS'.

*User input for Sales Document Number(VBELN) to fetch Header and Item data from table.
PARAMETERS : p_vbeln TYPE vbak-vbeln.

SELECT  a~vbeln,
        a~kunnr,
        a~erdat,
        c~name1,
        b~receipt_number,
        b~cheque_no,
        b~bank,
        b~RECEIPT_AMT

        FROM vbak AS a

        LEFT OUTER JOIN ztask_abapt AS b
        ON b~contract_number  = a~vbeln

        left outer join kna1 as c
        on c~kunnr  = a~kunnr

        WHERE a~vbeln = @p_vbeln INTO @wa_data.

  SELECT matnr,
         arktx,
         zmeng,
         zieme

         FROM vbap INTO TABLE @it_item
         WHERE vbeln = @p_vbeln  .

ENDSELECT.

*Method to fetch image from BDS and converting it to BMP
CALL METHOD cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp
  EXPORTING
    p_object       = c_OBJECT
    p_name         = lv_header_logo
    p_id           = c_ID
    p_btype        = c_BTYPE
  RECEIVING
    p_bmp          = lv_logo
  EXCEPTIONS
    not_found      = 1
    internal_error = 2
    OTHERS         = 3.

*Opens Adobe form session
CALL FUNCTION 'FP_JOB_OPEN'
  CHANGING
    ie_outputparams = ls_outputparams
  EXCEPTIONS
    cancel          = 1
    usage_error     = 2
    system_error    = 3
    internal_error  = 4
    OTHERS          = 5.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.
                         .

*Gets the generated FM name for the form
CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
  EXPORTING
    i_name     = 'ZSD_FORM_ABAP'
  IMPORTING
    e_funcname = lv_fm_name.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

*Calls the Adobe Form with data
CALL FUNCTION lv_fm_name                                                "'/1BCDWB/SM00001073'
  EXPORTING
*   /1BCDWB/DOCPARAMS  =
    wa_data            = wa_data
    it_item            = it_item
    lv_logo            = lv_logo
  IMPORTING
    /1bcdwb/formoutput = ls_pdf_file
  EXCEPTIONS
    usage_error        = 1
    system_error       = 2
    internal_error     = 3
    OTHERS             = 4.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

CALL FUNCTION 'FP_JOB_CLOSE'
  EXCEPTIONS
    usage_error    = 1
    system_error   = 2
    internal_error = 3
    OTHERS         = 4.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.
