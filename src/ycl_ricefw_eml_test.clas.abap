CLASS ycl_ricefw_eml_test DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS stage1_root_only
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS stage2_deep_create
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS ycl_ricefw_eml_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    stage1_root_only( out = out ).
    stage2_deep_create( out = out ).

  ENDMETHOD.


  METHOD stage1_root_only.

    out->write( '=== RICEFW Smoke Test — Stage 1: root only ===' ).
    out->write( `` ).

    "----------------------------------------------------------------
    " 0) Pre-cleanup — ลบทุก record ในตารางก่อนเริ่ม test (clean slate)
    "    NOTE: ลบ root จะ cascade ลบ child (_Owner/_Object/_Transport) ไปด้วย
    "    เพราะ composition + lock dependent by _RicefwMaster
    "----------------------------------------------------------------
    SELECT RicefwUUID
      FROM YR_RICEFW
      INTO TABLE @DATA(lt_old_uuid).

    IF lt_old_uuid IS NOT INITIAL.
      out->write( |พบ record เก่าค้างอยู่ { lines( lt_old_uuid ) } รายการ — ลบทั้งหมดก่อนเริ่ม test| ).

      MODIFY ENTITIES OF yr_ricefw
        ENTITY RicefwMaster
          DELETE
          FROM VALUE #( FOR ls_uuid IN lt_old_uuid
                      ( %tky = VALUE #( RicefwUUID = ls_uuid-RicefwUUID ) ) )
        FAILED   DATA(ls_pre_failed)
        REPORTED DATA(ls_pre_reported).

      COMMIT ENTITIES
        RESPONSE OF yr_ricefw
        FAILED   DATA(ls_pre_commit_failed)
        REPORTED DATA(ls_pre_commit_reported).

      LOOP AT ls_pre_commit_reported-ricefwmaster INTO DATA(ls_pre_r).
        IF ls_pre_r-%msg IS BOUND.
          out->write( |  REPORTED: { ls_pre_r-%msg->if_message~get_text( ) }| ).
        ENDIF.
      ENDLOOP.

      IF ls_pre_commit_failed-ricefwmaster IS INITIAL.
        out->write( 'ลบ record เก่าทั้งหมดสำเร็จ' ).
      ELSE.
        out->write( |ลบไม่สำเร็จ { lines( ls_pre_commit_failed-ricefwmaster ) } รายการ — test ถัดไปอาจ fail ที่ CREATE (duplicate)| ).
      ENDIF.
    ELSE.
      out->write( 'ไม่พบ record เก่าค้างอยู่ — เริ่ม test ได้เลย' ).
    ENDIF.

    out->write( `` ).

    "----------------------------------------------------------------
    " 1) Create a RICEFW master (root entity only, ยังไม่มี child)
    "----------------------------------------------------------------
    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        CREATE FIELDS ( RicefwID RicefwType DeliveryType Description PlanStart PlanFinish )
        WITH VALUE #( ( %cid         = 'ROOT1'
                        RicefwID     = 'SMOKE-001'
                        RicefwType   = 'RPT'
                        DeliveryType = 'NEW'
                        Description  = 'Smoke test record'
                        PlanStart    = '20260101'
                        PlanFinish   = '20260201' ) )
      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    out->write( '--- After CREATE (modify buffer) ---' ).
    LOOP AT ls_failed-ricefwmaster INTO DATA(ls_f1).
      out->write( |  FAILED key: { ls_f1-%tky-RicefwUUID }| ).
    ENDLOOP.
    LOOP AT ls_reported-ricefwmaster INTO DATA(ls_r1).
      IF ls_r1-%msg IS BOUND.
        out->write( |  REPORTED: { ls_r1-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_failed-ricefwmaster IS NOT INITIAL.
      out->write( 'CREATE failed — stopping.' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    "----------------------------------------------------------------
    " 2) Commit เพื่อ persist จริง — "on save" ทั้งหมด (determination/validation)
    "    จะรันจริงตอนนี้ ไม่ใช่ตอน MODIFY ENTITIES
    "----------------------------------------------------------------
    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    out->write( `` ).
    out->write( '--- After COMMIT ---' ).
    LOOP AT ls_commit_failed-ricefwmaster INTO DATA(ls_f2).
      out->write( |  FAILED key: { ls_f2-%tky-RicefwUUID }| ).
    ENDLOOP.
    LOOP AT ls_commit_reported-ricefwmaster INTO DATA(ls_r2).
      IF ls_r2-%msg IS BOUND.
        out->write( |  REPORTED: { ls_r2-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_commit_failed-ricefwmaster IS NOT INITIAL.
      out->write( 'COMMIT failed — stopping.' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    DATA(ls_new_key) = VALUE #( ls_mapped-ricefwmaster[ KEY cid COMPONENTS %cid = 'ROOT1' ]-%tky OPTIONAL ).
    out->write( |Committed. RicefwUUID = { ls_new_key-RicefwUUID }| ).

    "----------------------------------------------------------------
    " 3) Read กลับมาเช็คว่า determination ทำงานจริง (OverallStatus ต้องเป็น OPN)
    "----------------------------------------------------------------
    READ ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        ALL FIELDS
        WITH VALUE #( ( %tky = ls_new_key ) )
      RESULT DATA(lt_check).

    LOOP AT lt_check INTO DATA(ls_check).
      out->write( |RicefwID = { ls_check-RicefwID }  OverallStatus = { ls_check-OverallStatus }| ).
    ENDLOOP.

    "----------------------------------------------------------------
    " 4) Negative test — RicefwID ว่างต้องถูกปฏิเสธ
    "    validation เป็น on save ต้อง commit ก่อนถึงจะรันจริง
    "----------------------------------------------------------------
    out->write( `` ).
    out->write( '=== Negative test: empty RicefwID ===' ).

    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        CREATE FIELDS ( RicefwType DeliveryType Description )
        WITH VALUE #( ( %cid         = 'BAD1'
                        RicefwType   = 'RPT'
                        DeliveryType = 'NEW'
                        Description  = 'Should fail' ) )
      FAILED   DATA(ls_failed2)
      REPORTED DATA(ls_reported2).

    out->write( '--- After CREATE (modify buffer, ยังไม่ commit) ---' ).
    out->write( |  FAILED entries: { lines( ls_failed2-ricefwmaster ) }| ).
    out->write( |  REPORTED entries: { lines( ls_reported2-ricefwmaster ) }| ).
    out->write( '  (คาดว่าว่างทั้งคู่ — validation ยังไม่รันจนกว่าจะ commit)' ).

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed2)
      REPORTED DATA(ls_commit_reported2).

    out->write( `` ).
    out->write( '--- After COMMIT (validation ควรรันแล้ว) ---' ).
    LOOP AT ls_commit_failed2-ricefwmaster INTO DATA(ls_f3).
      out->write( |  FAILED key: { ls_f3-%tky-RicefwUUID }| ).
    ENDLOOP.
    LOOP AT ls_commit_reported2-ricefwmaster INTO DATA(ls_r3).
      IF ls_r3-%msg IS BOUND.
        out->write( |  REPORTED: { ls_r3-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_commit_failed2-ricefwmaster IS NOT INITIAL.
      out->write( 'Correctly rejected at COMMIT.' ).

      "-- record ที่ fail validation ยังค้างอยู่ใน RAP transactional buffer
      "-- ถ้าไม่ rollback จะถูกเอามา retry ซ้ำตอน COMMIT ENTITIES ครั้งถัดไป
      ROLLBACK ENTITIES.
    ELSE.
      out->write( 'WARNING: empty RicefwID was NOT rejected even after commit!' ).
    ENDIF.

    "----------------------------------------------------------------
    " 5) Cleanup — ลบ test record ทิ้ง กันรันซ้ำแล้วชน unique index
    "----------------------------------------------------------------
    out->write( `` ).
    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        DELETE
        FROM VALUE #( ( %tky = ls_new_key ) )
      FAILED   DATA(ls_del_failed)
      REPORTED DATA(ls_del_reported).

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_del_commit_failed)
      REPORTED DATA(ls_del_commit_reported).

    out->write( '--- Cleanup result ---' ).
    LOOP AT ls_del_commit_failed-ricefwmaster INTO DATA(ls_f4).
      out->write( |  FAILED key: { ls_f4-%tky-RicefwUUID }| ).
    ENDLOOP.
    LOOP AT ls_del_commit_reported-ricefwmaster INTO DATA(ls_r4).
      IF ls_r4-%msg IS BOUND.
        out->write( |  REPORTED: { ls_r4-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_del_failed-ricefwmaster IS INITIAL AND ls_del_commit_failed-ricefwmaster IS INITIAL.
      out->write( 'Cleanup: test record deleted.' ).
    ELSE.
      out->write( 'Cleanup FAILED — กรุณาลบ SMOKE-001 เองด้วย' ).
    ENDIF.

    out->write( `` ).
    out->write( '=== Stage 1 Done ===' ).

  ENDMETHOD.


  METHOD stage2_deep_create.

    out->write( `` ).
    out->write( '=== RICEFW Smoke Test — Stage 2: deep-create (root + Owner ในคำสั่งเดียว) ===' ).
    out->write( `` ).

    "----------------------------------------------------------------
    " 0) Pre-cleanup — ลบ SMOKE-002 เก่าถ้ามีค้าง
    "    ลบ root จะ cascade ลบ child ทั้งหมดเองอยู่แล้ว (composition)
    "----------------------------------------------------------------
    SELECT RicefwUUID
      FROM YR_RICEFW
      WHERE RicefwID = 'SMOKE-002'
      INTO TABLE @DATA(lt_old_uuid).

    IF lt_old_uuid IS NOT INITIAL.
      MODIFY ENTITIES OF yr_ricefw
        ENTITY RicefwMaster
          DELETE
          FROM VALUE #( FOR ls_uuid IN lt_old_uuid
                      ( %tky = VALUE #( RicefwUUID = ls_uuid-RicefwUUID ) ) )
        FAILED   DATA(ls_pre_failed)
        REPORTED DATA(ls_pre_reported).

      COMMIT ENTITIES
        RESPONSE OF yr_ricefw
        FAILED   DATA(ls_pre_commit_failed)
        REPORTED DATA(ls_pre_commit_reported).

      out->write( |พบ record เก่า SMOKE-002 { lines( lt_old_uuid ) } รายการ — ลบก่อนเริ่ม test| ).
      out->write( `` ).
    ENDIF.

    "----------------------------------------------------------------
    " 1) Deep create — root + Owner child ในคำสั่งเดียว
    "    โครงสร้าง 2 ชั้นของ CREATE BY \_Owner:
    "      ชั้นนอก  = ระบุ parent (%cid_ref ชี้กลับไปที่ %cid ของ root ในคำสั่งเดียวกัน)
    "      %target = internal table ของ child ที่จะสร้าง — field ของ Owner อยู่ในนี้
    "----------------------------------------------------------------
    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        CREATE FIELDS ( RicefwID RicefwType DeliveryType Description PlanStart PlanFinish )
        WITH VALUE #( ( %cid         = 'ROOT2'
                        RicefwID     = 'SMOKE-002'
                        RicefwType   = 'RPT'
                        DeliveryType = 'NEW'
                        Description  = 'Smoke test deep-create'
                        PlanStart    = '20260101'
                        PlanFinish   = '20260201' ) )
        CREATE BY \_Owner
          FIELDS ( OwnerID OwnerName Role Progress )
          WITH VALUE #( ( %cid_ref = 'ROOT2'
                          %target  = VALUE #( ( %cid      = 'OWNER1'
                                                OwnerID   = 'OWN-001'
                                                OwnerName = 'Somchai Test'
                                                Role      = 'PM'
                                                Progress  = 0 ) ) ) )
      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    out->write( '--- After deep CREATE (modify buffer) ---' ).
    out->write( |  FAILED root entries: { lines( ls_failed-ricefwmaster ) }| ).
    out->write( |  FAILED owner entries: { lines( ls_failed-owner ) }| ).
    LOOP AT ls_reported-ricefwmaster INTO DATA(ls_r_root).
      IF ls_r_root-%msg IS BOUND.
        out->write( |  REPORTED (root): { ls_r_root-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.
    LOOP AT ls_reported-owner INTO DATA(ls_r_owner).
      IF ls_r_owner-%msg IS BOUND.
        out->write( |  REPORTED (owner): { ls_r_owner-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_failed-ricefwmaster IS NOT INITIAL OR ls_failed-owner IS NOT INITIAL.
      out->write( 'Deep CREATE failed — stopping Stage 2.' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    "----------------------------------------------------------------
    " 2) Commit — validation/determination ทั้งหมด (root + child) รันตอนนี้
    "----------------------------------------------------------------
    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    out->write( `` ).
    out->write( '--- After COMMIT ---' ).
    out->write( |  FAILED root entries: { lines( ls_commit_failed-ricefwmaster ) }| ).
    out->write( |  FAILED owner entries: { lines( ls_commit_failed-owner ) }| ).
    LOOP AT ls_commit_reported-ricefwmaster INTO DATA(ls_cr_root).
      IF ls_cr_root-%msg IS BOUND.
        out->write( |  REPORTED (root): { ls_cr_root-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.
    LOOP AT ls_commit_reported-owner INTO DATA(ls_cr_owner).
      IF ls_cr_owner-%msg IS BOUND.
        out->write( |  REPORTED (owner): { ls_cr_owner-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_commit_failed-ricefwmaster IS NOT INITIAL OR ls_commit_failed-owner IS NOT INITIAL.
      out->write( 'COMMIT failed — stopping Stage 2.' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    DATA(ls_root_key) = VALUE #( ls_mapped-ricefwmaster[ KEY cid COMPONENTS %cid = 'ROOT2' ]-%tky OPTIONAL ).
    DATA(ls_owner_key) = VALUE #( ls_mapped-owner[ KEY cid COMPONENTS %cid = 'OWNER1' ]-%tky OPTIONAL ).
    out->write( |Committed. Root RicefwUUID = { ls_root_key-RicefwUUID }| ).
    out->write( |            Owner OwnerUUID = { ls_owner_key-OwnerUUID }| ).

    "----------------------------------------------------------------
    " 3) Read กลับมาเช็คว่า child ถูกสร้างจริง และ RicefwUUID ถูกเติมให้อัตโนมัติ
    "    (field ( readonly ) RicefwUUID ใน bdef — RAP เติมเองผ่าน composition)
    "----------------------------------------------------------------
    READ ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        BY \_Owner
        ALL FIELDS
        WITH VALUE #( ( %tky = ls_root_key ) )
      RESULT DATA(lt_owner_check).

    out->write( `` ).
    IF lt_owner_check IS INITIAL.
      out->write( 'WARNING: ไม่พบ Owner child เลย — deep-create อาจไม่สำเร็จจริง' ).
    ELSE.
      LOOP AT lt_owner_check INTO DATA(ls_owner_check).
        out->write( |Owner: OwnerID = { ls_owner_check-OwnerID }  Name = { ls_owner_check-OwnerName }  Role = { ls_owner_check-Role }| ).
        IF ls_owner_check-RicefwUUID = ls_root_key-RicefwUUID.
          out->write( '  RicefwUUID ตรงกับ root — composition เติม FK ให้ถูกต้อง' ).
        ELSE.
          out->write( |  WARNING: RicefwUUID ไม่ตรงกับ root! ({ ls_owner_check-RicefwUUID })| ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    "----------------------------------------------------------------
    " 4) Cleanup — ลบ root แล้วเช็คว่า child ถูก cascade ลบตามไปด้วยจริง
    "----------------------------------------------------------------
    out->write( `` ).
    MODIFY ENTITIES OF yr_ricefw
      ENTITY RicefwMaster
        DELETE
        FROM VALUE #( ( %tky = ls_root_key ) )
      FAILED   DATA(ls_del_failed)
      REPORTED DATA(ls_del_reported).

    COMMIT ENTITIES
      RESPONSE OF yr_ricefw
      FAILED   DATA(ls_del_commit_failed)
      REPORTED DATA(ls_del_commit_reported).

    out->write( '--- Cleanup result ---' ).
    LOOP AT ls_del_commit_reported-ricefwmaster INTO DATA(ls_dr_root).
      IF ls_dr_root-%msg IS BOUND.
        out->write( |  REPORTED: { ls_dr_root-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF ls_del_failed-ricefwmaster IS INITIAL AND ls_del_commit_failed-ricefwmaster IS INITIAL.
      out->write( 'Cleanup: root deleted.' ).

      " ยืนยัน cascade delete — child ต้องหายตามไปด้วย
      SELECT COUNT(*)
        FROM yricefw_owner
        WHERE ricefw_uuid = @ls_root_key-RicefwUUID
        INTO @DATA(lv_owner_left).

      IF lv_owner_left = 0.
        out->write( 'Cascade delete ทำงานถูกต้อง — Owner child ถูกลบตาม root ไปด้วย' ).
      ELSE.
        out->write( |WARNING: ยังเหลือ Owner child ค้างอยู่ { lv_owner_left } รายการ| ).
      ENDIF.
    ELSE.
      out->write( 'Cleanup FAILED — กรุณาลบ SMOKE-002 เองด้วย' ).
    ENDIF.

    out->write( `` ).
    out->write( '=== Stage 2 Done ===' ).

  ENDMETHOD.

ENDCLASS.
