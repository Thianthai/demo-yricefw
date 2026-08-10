CLASS lhc_owner DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateProgress FOR VALIDATE ON SAVE
      keys FOR Owner~validateProgress.

ENDCLASS.

CLASS lhc_owner IMPLEMENTATION.

  METHOD validateProgress.

    READ ENTITIES OF yr_ricefw IN LOCAL MODE
      ENTITY Owner
        FIELDS ( Progress )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_owner).

    LOOP AT lt_owner INTO DATA(ls_owner)
      WHERE Progress > 100.

      APPEND VALUE #( %tky = ls_owner-%tky
                      %msg = new_message( id = 'YRICEFW'
                                          number = '004'
                                          severity = if_abap_behv_message=>severity-error )
                      %element-Progress = if_abap_behv=>mk-on
                    ) TO reported-owner.

      APPEND VALUE #( %tky = ls_owner-%tky ) TO failed-owner.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_RicefwMaster DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR RicefwMaster RESULT result.

    METHODS setinitialstatus FOR DETERMINE ON MODIFY
      keys FOR ricefwmaster~setinitialstatus.

    METHODS validatericefwid FOR VALIDATE ON SAVE
      keys FOR ricefwmaster~validatericefwid.

    METHODS validatedates FOR VALIDATE ON SAVE
      keys FOR ricefwmaster~validatedates.

ENDCLASS.

CLASS lhc_RicefwMaster IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD setInitialStatus.

    MODIFY ENTITIES OF yr_ricefw IN LOCAL MODE
      ENTITY RicefwMaster
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                         OverallStatus = 'OPN' ) )
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

  ENDMETHOD.

  METHOD validateRicefwId.

    " ดึงค่า RicefwID ปัจจุบันของแต่ละตัวออกมาเก็บใน lt_ricefw_master
    READ ENTITIES OF yr_ricefw IN LOCAL MODE
      ENTITY RicefwMaster
        FIELDS ( RicefwID )
        WITH CORRESPONDING #( keys ) "Parameter ของ Instance ที่กำลังจะ Save
      RESULT DATA(lt_ricefw_master).

    " (1) ห้ามว่าง
    LOOP AT lt_ricefw_master INTO DATA(ls_ricefw_master)
      WHERE RicefwID IS INITIAL.

      APPEND VALUE #( %tky = ls_ricefw_master-%tky "บอกว่า message นี้เป็นของ instance ไหน
                      %state_area = 'VALIDATE_RICEFW_ID' "ใช้ตอน RAP ตัดสินใจว่าต้องเช็ค validation นี้ใหม่เมื่อ field ไหนถูกแก้ (จับคู่กับ field ... state_area ใน bdef ถ้ามี)
                      %msg = new_message( id = 'YRICEFW' "ข้อความจริงจาก message class YRICEFW เลข 001
                                          number = '001'
                                          severity = if_abap_behv_message=>severity-error )
                      %element-RicefwID = if_abap_behv=>mk-on "Highlight error ไปที่ field บน Fiori Elements
                    ) TO reported-ricefwmaster.

      " Block การ Save
      APPEND VALUE #( %tky = ls_ricefw_master-%tky ) TO failed-ricefwmaster.
    ENDLOOP.

    " (2) ห้ามซ้ำ — เช็คทั้ง active data (DB) และ instance อื่นในชุดเดียวกันที่กำลัง validate
    DATA(lt_check) = lt_ricefw_master.
    DELETE lt_check WHERE RicefwID IS INITIAL.

    IF lt_check IS NOT INITIAL.

      SELECT ricefw_id, ricefw_uuid
        FROM yricefw_hdr
        FOR ALL ENTRIES IN @lt_check
        WHERE ricefw_id = @lt_check-RicefwID
          AND ricefw_uuid <> @lt_check-RicefwUUID
        INTO TABLE @DATA(lt_db_dup).

      LOOP AT lt_check INTO ls_ricefw_master.

        DATA(lv_dup_in_db) = xsdbool( line_exists( lt_db_dup[ ricefw_id = ls_ricefw_master-RicefwID ] ) ).

        DATA(lv_count) = 0.
        LOOP AT lt_check INTO DATA(ls_check_dup)
          WHERE RicefwID = ls_ricefw_master-RicefwID.
          lv_count = lv_count + 1.
        ENDLOOP.
        DATA(lv_dup_in_request) = xsdbool( lv_count > 1 ).

        IF lv_dup_in_db = abap_true OR lv_dup_in_request = abap_true.
          APPEND VALUE #( %tky = ls_ricefw_master-%tky
                          %state_area = 'VALIDATE_RICEFW_ID'
                          %msg = new_message( id = 'YRICEFW'
                                              number = '002'
                                              severity = if_abap_behv_message=>severity-error )
                          %element-RicefwID = if_abap_behv=>mk-on
                        ) TO reported-ricefwmaster.

          APPEND VALUE #( %tky = ls_ricefw_master-%tky ) TO failed-ricefwmaster.
        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF yr_ricefw IN LOCAL MODE
      ENTITY RicefwMaster
        FIELDS ( PlanStart PlanFinish )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_ricefw_master).

    LOOP AT lt_ricefw_master INTO DATA(ls_ricefw_master).

      IF ls_ricefw_master-PlanStart  IS NOT INITIAL AND
         ls_ricefw_master-PlanFinish IS NOT INITIAL AND
         ls_ricefw_master-PlanFinish < ls_ricefw_master-PlanStart.

        APPEND VALUE #( %tky = ls_ricefw_master-%tky
                        %msg = new_message( id = 'YRICEFW'
                                            number = '003'
                                            severity = if_abap_behv_message=>severity-error )
                        %element-PlanFinish = if_abap_behv=>mk-on
                      ) TO reported-ricefwmaster.

        APPEND VALUE #( %tky = ls_ricefw_master-%tky ) TO failed-ricefwmaster.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
