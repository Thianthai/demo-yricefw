CLASS ycl_ricefw_gen DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_seed,
             ricefw_id     TYPE yricefw_hdr-ricefw_id,
             ricefw_type   TYPE yricefw_hdr-ricefw_type,
             description   TYPE yricefw_hdr-description,
             status        TYPE yricefw_hdr-overall_status,
             plan_start    TYPE yricefw_hdr-plan_start,
             plan_finish   TYPE yricefw_hdr-plan_finish,
             remark        TYPE yricefw_hdr-remark,

             abap_id       TYPE yricefw_owner-owner_id,
             abap_name     TYPE yricefw_owner-owner_name,
             abap_progress TYPE yricefw_owner-progress,

             func_id       TYPE yricefw_owner-owner_id,
             func_name     TYPE yricefw_owner-owner_name,
             func_progress TYPE yricefw_owner-progress,

             wb_id         TYPE yricefw_trsp-transport_id,
             wb_status     TYPE yricefw_trsp-transport_status,
             cus_id        TYPE yricefw_trsp-transport_id,
             cus_status    TYPE yricefw_trsp-transport_status,
             released_on   TYPE yricefw_trsp-released_on,
           END OF ty_seed,
           tt_seed TYPE STANDARD TABLE OF ty_seed WITH EMPTY KEY.

    METHODS build_seed
      RETURNING VALUE(rt_seed) TYPE tt_seed.

    METHODS delete_all
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS create_all
      IMPORTING out     TYPE REF TO if_oo_adt_classrun_out
                it_seed TYPE tt_seed.

    METHODS update_status
      IMPORTING out     TYPE REF TO if_oo_adt_classrun_out
                it_seed TYPE tt_seed.

ENDCLASS.


CLASS ycl_ricefw_gen IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( '=== RICEFW Demo Data Generator ===' ).
    out->write( `` ).

    DATA(lt_seed) = build_seed( ).

    delete_all( out = out ).
    create_all( out = out it_seed = lt_seed ).
    update_status( out = out it_seed = lt_seed ).

    out->write( `` ).
    out->write( '=== Done ===' ).

  ENDMETHOD.

  METHOD build_seed.

    rt_seed = VALUE #(

      ( ricefw_id = 'YSDR001' ricefw_type = 'RPT'
        description = 'Sales Order Backlog Report'
        status = 'CLS' plan_start = '20260105' plan_finish = '20260331'
        abap_id = 'ABAP01' abap_name = 'Baramee Sukhong'       abap_progress = 100
        func_id = 'FUNC01' func_name = 'James Carter'          func_progress = 100
        wb_id = 'S4DK900101' wb_status = 'IMP'
        cus_id = 'S4DK900102' cus_status = 'IMP' released_on = '20260320' )

      ( ricefw_id = 'YSDR002' ricefw_type = 'RPT'
        description = 'Customer Billing Summary Report'
        status = 'UAT' plan_start = '20260316' plan_finish = '20260831'
        abap_id = 'ABAP02' abap_name = 'Chawanat Nimphung'     abap_progress = 95
        func_id = 'FUNC02' func_name = 'Emily Brooks'          func_progress = 90
        wb_id = 'S4DK900103' wb_status = 'IMP'
        cus_id = 'S4DK900104' cus_status = 'IMP' released_on = '20260615' )

      ( ricefw_id = 'YSDR003' ricefw_type = 'RPT'
        description = 'Delivery Performance Report'
        status = 'DEV' plan_start = '20260713' plan_finish = '20261231'
        abap_id = 'ABAP03' abap_name = 'Chayaporn Ditsakul'    abap_progress = 35
        func_id = 'FUNC03' func_name = 'Michael Reed'          func_progress = 50
        wb_id = 'S4DK900105' wb_status = 'MOD'
        cus_id = 'S4DK900106' cus_status = 'MOD' )

      ( ricefw_id = 'YMMI001' ricefw_type = 'INTF'
        description = 'Vendor Master Data Inbound Interface'
        status = 'SIT' plan_start = '20260413' plan_finish = '20260930'
        abap_id = 'ABAP04' abap_name = 'Kwankamon Tansopaluck' abap_progress = 85
        func_id = 'FUNC04' func_name = 'Sarah Mitchell'        func_progress = 85
        wb_id = 'S4DK900107' wb_status = 'IMP'
        cus_id = 'S4DK900108' cus_status = 'IMP' released_on = '20260706' )

      ( ricefw_id = 'YMMI002' ricefw_type = 'INTF'
        description = 'Purchase Order Outbound Interface to Supplier Portal'
        status = 'HLD' plan_start = '20260202' plan_finish = '20260630'
        remark = 'Blocked by failed transport import in QA. Waiting for basis team.'
        abap_id = 'ABAP05' abap_name = 'Napat Wichaisuttigul'  abap_progress = 60
        func_id = 'FUNC05' func_name = 'David Foster'          func_progress = 50
        wb_id = 'S4DK900109' wb_status = 'ERR'
        cus_id = 'S4DK900110' cus_status = 'IMP' released_on = '20260605' )

      ( ricefw_id = 'YMMI003' ricefw_type = 'INTF'
        description = 'Goods Receipt Confirmation Interface'
        status = 'PND' plan_start = '20260817' plan_finish = '20270129'
        abap_id = 'ABAP06' abap_name = 'Navapat Tongpubet'     abap_progress = 0
        func_id = 'FUNC06' func_name = 'Laura Bennett'         func_progress = 10
        wb_id = 'S4DK900111' wb_status = 'MOD'
        cus_id = 'S4DK900112' cus_status = 'MOD' )

      ( ricefw_id = 'YFIE001' ricefw_type = 'ENH'
        description = 'Custom Field Validation on Journal Entry'
        status = 'FAT' plan_start = '20260511' plan_finish = '20261030'
        abap_id = 'ABAP07' abap_name = 'Parinya Kijwattanaboon' abap_progress = 80
        func_id = 'FUNC07' func_name = 'Robert Hayes'          func_progress = 75
        wb_id = 'S4DK900113' wb_status = 'REL'
        cus_id = 'S4DK900114' cus_status = 'REL' released_on = '20260803' )

      ( ricefw_id = 'YFIE002' ricefw_type = 'ENH'
        description = 'Automatic Cost Center Derivation Enhancement'
        status = 'UT' plan_start = '20260615' plan_finish = '20261130'
        abap_id = 'ABAP08' abap_name = 'Saran Trakarnvanich'   abap_progress = 70
        func_id = 'FUNC08' func_name = 'Jennifer Walsh'        func_progress = 60
        wb_id = 'S4DK900115' wb_status = 'MOD'
        cus_id = 'S4DK900116' cus_status = 'MOD' )

      ( ricefw_id = 'YFIE003' ricefw_type = 'ENH'
        description = 'Payment Terms Check on Vendor Invoice'
        status = 'CAN' plan_start = '20260302' plan_finish = '20260731'
        remark = 'Cancelled after scope review - covered by standard configuration.'
        abap_id = 'ABAP09' abap_name = 'Tanet Juengtavonanan'  abap_progress = 15
        func_id = 'FUNC09' func_name = 'Daniel Prescott'       func_progress = 25
        wb_id = 'S4DK900117' wb_status = 'MOD'
        cus_id = 'S4DK900118' cus_status = 'MOD' )

      ( ricefw_id = 'YFIF001' ricefw_type = 'FORM'
        description = 'Customer Invoice Print Form'
        status = 'OPN' plan_start = '20260914' plan_finish = '20270226'
        abap_id = 'ABAP10' abap_name = 'Thatpicha Wongsa'      abap_progress = 0
        func_id = 'FUNC10' func_name = 'Karen Sullivan'        func_progress = 0
        wb_id = 'S4DK900119' wb_status = 'MOD'
        cus_id = 'S4DK900120' cus_status = 'MOD' )

    ).

  ENDMETHOD.

  METHOD delete_all.

    SELECT RicefwUUID
      FROM YR_RICEFW
      INTO TABLE @DATA(lt_old).

    IF lt_old IS INITIAL.
      out->write( 'ไม่มีข้อมูลเดิม — เริ่มสร้างได้เลย' ).
      out->write( `` ).
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        DELETE
        FROM VALUE #( FOR ls_old IN lt_old
                       ( %tky = VALUE #( RicefwUUID = ls_old-RicefwUUID ) ) )
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed-ricefwmaster IS INITIAL.
      out->write( |ลบข้อมูลเดิม { lines( lt_old ) } รายการ| ).
    ELSE.
      out->write( |ลบไม่สำเร็จ { lines( ls_commit_failed-ricefwmaster ) } รายการ| ).
      LOOP AT ls_commit_reported-ricefwmaster INTO DATA(ls_msg).
        IF ls_msg-%msg IS BOUND.
          out->write( |  { ls_msg-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      ROLLBACK ENTITIES.
    ENDIF.

    out->write( `` ).

  ENDMETHOD.

  METHOD create_all.

    DATA lt_root      TYPE TABLE FOR CREATE yr_ricefw.
    DATA lt_owner     TYPE TABLE FOR CREATE yr_ricefw\_Owner.
    DATA lt_transport TYPE TABLE FOR CREATE yr_ricefw\_Transport.

    LOOP AT it_seed INTO DATA(ls_seed).

      DATA(lv_cid) = |ROOT{ sy-tabix }|.

      APPEND VALUE #( %cid         = lv_cid
                      RicefwID     = ls_seed-ricefw_id
                      RicefwType   = ls_seed-ricefw_type
                      DeliveryType = 'NEW'          "ทุกตัวเป็น NEW ตาม spec
                      Description  = ls_seed-description
                      PlanStart    = ls_seed-plan_start
                      PlanFinish   = ls_seed-plan_finish
                      Remark       = ls_seed-remark )
        TO lt_root.

      APPEND VALUE #(
        %cid_ref = lv_cid
        %target  = VALUE #(
          ( %cid      = |OWN{ sy-tabix }A|
            OwnerID   = ls_seed-abap_id
            OwnerName = ls_seed-abap_name
            Role      = 'AB'
            Progress  = ls_seed-abap_progress )
          ( %cid      = |OWN{ sy-tabix }F|
            OwnerID   = ls_seed-func_id
            OwnerName = ls_seed-func_name
            Role      = 'FN'
            Progress  = ls_seed-func_progress ) ) )
        TO lt_owner.

      APPEND VALUE #(
        %cid_ref = lv_cid
        %target  = VALUE #(
          ( %cid            = |TRP{ sy-tabix }W|
            TransportType   = 'WB'
            TransportID     = ls_seed-wb_id
            Description     = |AB: { ls_seed-ricefw_id } V1.0|
            TransportStatus = ls_seed-wb_status
            ImportSequence  = 1
            ReleasedOn      = ls_seed-released_on )
          ( %cid            = |TRP{ sy-tabix }C|
            TransportType   = 'CUS'
            TransportID     = ls_seed-cus_id
            Description     = |AB: Constant Parameter for { ls_seed-ricefw_id } V1.0|
            TransportStatus = ls_seed-cus_status
            ImportSequence  = 2
            ReleasedOn      = ls_seed-released_on ) ) )
        TO lt_transport.

    ENDLOOP.

    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        CREATE FIELDS ( RicefwID RicefwType DeliveryType Description
                        PlanStart PlanFinish Remark )
        WITH lt_root

        CREATE BY \_Owner
          FIELDS ( OwnerID OwnerName Role Progress )
          WITH lt_owner

        CREATE BY \_Transport
          FIELDS ( TransportType TransportID Description TransportStatus
                   ImportSequence ReleasedOn )
          WITH lt_transport

      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-ricefwmaster IS NOT INITIAL
       OR ls_failed-owner     IS NOT INITIAL
       OR ls_failed-transport IS NOT INITIAL.
      out->write( 'CREATE ไม่ผ่าน:' ).
      LOOP AT ls_reported-ricefwmaster INTO DATA(ls_r1).
        IF ls_r1-%msg IS BOUND.
          out->write( |  root:      { ls_r1-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      LOOP AT ls_reported-owner INTO DATA(ls_r2).
        IF ls_r2-%msg IS BOUND.
          out->write( |  owner:     { ls_r2-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      LOOP AT ls_reported-transport INTO DATA(ls_r3).
        IF ls_r3-%msg IS BOUND.
          out->write( |  transport: { ls_r3-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed-ricefwmaster IS NOT INITIAL
       OR ls_commit_failed-owner     IS NOT INITIAL
       OR ls_commit_failed-transport IS NOT INITIAL.
      out->write( 'COMMIT ไม่ผ่าน:' ).
      LOOP AT ls_commit_reported-ricefwmaster INTO DATA(ls_c1).
        IF ls_c1-%msg IS BOUND.
          out->write( |  { ls_c1-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    out->write( |สร้างแล้ว: { lines( lt_root ) } RICEFW · { lines( lt_root ) * 2 } owner · { lines( lt_root ) * 2 } transport| ).

  ENDMETHOD.

  METHOD update_status.

    SELECT RicefwUUID, RicefwID
      FROM YR_RICEFW
      INTO TABLE @DATA(lt_created).

    DATA lt_upd TYPE TABLE FOR UPDATE yr_ricefw.

    LOOP AT it_seed INTO DATA(ls_seed).

      DATA(lv_uuid) = VALUE #( lt_created[ RicefwID = ls_seed-ricefw_id ]-RicefwUUID OPTIONAL ).

      IF lv_uuid IS INITIAL.
        out->write( |  ข้าม { ls_seed-ricefw_id } — หา record ไม่เจอ| ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky          = VALUE #( RicefwUUID = lv_uuid )
                      OverallStatus = ls_seed-status )
        TO lt_upd.

    ENDLOOP.

    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        UPDATE FIELDS ( OverallStatus )
        WITH lt_upd
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed-ricefwmaster IS NOT INITIAL.
      out->write( 'UPDATE status ไม่ผ่าน:' ).
      LOOP AT ls_commit_reported-ricefwmaster INTO DATA(ls_msg).
        IF ls_msg-%msg IS BOUND.
          out->write( |  { ls_msg-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    out->write( |ตั้ง OverallStatus แล้ว { lines( lt_upd ) } รายการ| ).
    out->write( `` ).

    " สรุปผลจากข้อมูลที่ persist จริง
    SELECT RicefwID, RicefwType, OverallStatus, Description
      FROM YR_RICEFW
      ORDER BY RicefwID
      INTO TABLE @DATA(lt_final).

    out->write( '--- ผลลัพธ์ ---' ).
    LOOP AT lt_final INTO DATA(ls_final).
      out->write( |{ ls_final-RicefwID WIDTH = 10 }{ ls_final-RicefwType WIDTH = 6 }| &&
                  |{ ls_final-OverallStatus WIDTH = 5 }{ ls_final-Description }| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
