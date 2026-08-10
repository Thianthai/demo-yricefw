# Phase 5 — Behavior Definition & Implementation 🔄

Package: `YRICEFW` · Behavior Definition ชื่อ `YR_RICEFW` (ชื่อเดียวกับ root view — RAP บังคับ)

---

## 5.1 — bdef ฉบับ minimal (CRUD + Draft) ✅

### Object ที่เกิดขึ้น

| Object | ที่มา | หมายเหตุ |
|---|---|---|
| `YR_RICEFW` (bdef) | เขียนเอง | 4 `define behavior for` block ในไฟล์เดียว (root + 3 child) |
| `YBP_R_RICEFW` | Quick fix จาก bdef | Behavior pool — **ชื่อ ADT auto-generate มี `_R_`** ไม่ใช่ `YBP_RICEFW` ตามที่วางแผนไว้แต่แรก |
| `LHC_RicefwMaster` | Quick fix จาก bdef | Local handler class ใน `YBP_R_RICEFW` — มี stub `get_instance_authorizations` ว่างเปล่า (Phase 9 ค่อยเติม) |
| `YRICEFW_HDR_D` | Quick fix จาก bdef | Draft table ของ root |
| `YRICEFW_OWNER_D` | Quick fix จาก bdef | Draft table ของ owner — ตั้งชื่อเต็ม ไม่ย่อ (15 ตัวอักษร ไม่เกิน 16) |
| `YRICEFW_OBJ_D` | Quick fix จาก bdef | Draft table ของ object |
| `YRICEFW_TRSP_D` | Quick fix จาก bdef | Draft table ของ transport |

### ⚠️ บทเรียน: `mapping for ... corresponding` — ต้องมีทุก entity

**อาการ**: activate ครั้งแรกผ่าน (0 error) แต่มี warning เพียบแบบนี้ทุก field ที่ชื่อมากกว่า 1 คำ:

```
Field "OWNERID" of entity "YI_RICEFW_OWNER" does not have a mapping to table
"YRICEFW_OWNER". A "mapping" definition should be added.
```

**สาเหตุ**: managed persistence จับคู่ field ด้วยการเทียบชื่อแบบ **lowercase ตรงตัว** ระหว่าง
CDS element กับ table column — **ไม่ได้อ่าน `as` alias ในตัว CDS view เลย**

```
role       → lowercase "role"        == table field "role"        ✅ จับคู่เองได้ (คำเดียว)
owner_id   → element "OwnerID" lowercase "ownerid" ≠ "owner_id"    ❌ ไม่ตรง (table มี _)
```

เราตั้งใจใช้ `snake_case` ที่ table กับ `UpperCamelCase` ที่ CDS (convention ตั้งแต่ Phase 3)
field ไหนมีมากกว่า 1 คำจะชนปัญหานี้เสมอ ยกเว้นคำเดียวโดดๆ (`role`, `progress`, `remark`, `description`)

**ทางแก้**: ประกาศ `mapping for <table> corresponding { Element = field; ... }` เป็นบรรทัดแรก
ในตัว `{ }` ของแต่ละ `define behavior for` — map **ทุก field ที่ persist** ไม่ใช่แค่ตัวที่ error
(รวม key ด้วย เพื่อความชัดเจน แม้บาง field จะ auto-match ได้อยู่แล้วก็ตาม)

### 💡 สังเกต: Draft table ไม่ต้องมี mapping เลย

Draft table ที่ ADT generate ให้ **ไม่มี `_` ใน column name เลย** — สร้างจาก CDS element name
โดยตรง (`RicefwUUID` → lowercase ตรงๆ → `ricefwuuid`) ไม่ใช่จาก table column เดิม

```
Active table   yricefw_hdr    : ricefw_uuid, overall_status   (มี _)
Draft table    yricefw_hdr_d  : ricefwuuid, overallstatus     (ไม่มี _)
```

เพราะแบบนี้ draft table จึง**ตรงกับ CDS element โดยอัตโนมัติเสมอ** ไม่ต้องมี `mapping for`
— warning ที่เจอทั้งหมดเกิดกับ `persistent table` (ที่เราตั้ง `_` เอง) เท่านั้น ไม่เกิดกับ
`draft table` สักบรรทัดเดียว

---

## bdef Source (ฉบับใช้งานจริง — activate ผ่าน 0 error 0 warning)

```abap
managed implementation in class ybp_r_ricefw unique;
strict ( 2 );
with draft;

define behavior for YR_RICEFW alias RicefwMaster
persistent table yricefw_hdr
draft table yricefw_hdr_d
lock master
total etag LastChangedAt
authorization master ( instance )
etag master LocalLastChangedAt
{
  mapping for yricefw_hdr corresponding
    {
      RicefwUUID          = ricefw_uuid;
      RicefwID              = ricefw_id;
      RicefwType              = ricefw_type;
      DeliveryType              = delivery_type;
      Description                = description;
      OverallStatus                = overall_status;
      PlanStart                     = plan_start;
      PlanFinish                     = plan_finish;
      Remark                          = remark;
      CreatedBy                        = created_by;
      CreatedAt                         = created_at;
      LastChangedBy                      = last_changed_by;
      LastChangedAt                       = last_changed_at;
      LocalLastChangedAt                   = local_last_changed_at;
    }

  field ( numbering : managed, readonly ) RicefwUUID;
  field ( mandatory ) RicefwID, RicefwType, DeliveryType, Description;
  field ( readonly ) CreatedBy, CreatedAt, LastChangedBy, LastChangedAt, LocalLastChangedAt;

  create;
  update;
  delete;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;

  association _Owner     { create; with draft; }
  association _Object    { create; with draft; }
  association _Transport { create; with draft; }
}

define behavior for YI_RICEFW_OWNER alias Owner
persistent table yricefw_owner
draft table yricefw_owner_d
lock dependent by _RicefwMaster
authorization dependent by _RicefwMaster
etag master LocalLastChangedAt
{
  mapping for yricefw_owner corresponding
    {
      OwnerUUID          = owner_uuid;
      RicefwUUID           = ricefw_uuid;
      OwnerID                = owner_id;
      OwnerName                = owner_name;
      Role                       = role;
      Progress                    = progress;
      CreatedBy                    = created_by;
      CreatedAt                     = created_at;
      LastChangedBy                  = last_changed_by;
      LocalLastChangedAt               = local_last_changed_at;
    }

  field ( numbering : managed, readonly ) OwnerUUID;
  field ( readonly ) RicefwUUID;
  field ( mandatory ) OwnerID, OwnerName, Role;
  field ( readonly ) CreatedBy, CreatedAt, LastChangedBy, LocalLastChangedAt;

  update;
  delete;

  association _RicefwMaster { with draft; }
}

define behavior for YI_RICEFW_OBJECT alias Object
persistent table yricefw_obj
draft table yricefw_obj_d
lock dependent by _RicefwMaster
authorization dependent by _RicefwMaster
etag master LocalLastChangedAt
{
  mapping for yricefw_obj corresponding
    {
      ObjectUUID         = object_uuid;
      RicefwUUID           = ricefw_uuid;
      ObjectName             = object_name;
      ObjectType               = object_type;
      Description                = description;
      CreatedBy                   = created_by;
      CreatedAt                    = created_at;
      LastChangedBy                 = last_changed_by;
      LocalLastChangedAt              = local_last_changed_at;
    }

  field ( numbering : managed, readonly ) ObjectUUID;
  field ( readonly ) RicefwUUID;
  field ( mandatory ) ObjectName, ObjectType;
  field ( readonly ) CreatedBy, CreatedAt, LastChangedBy, LocalLastChangedAt;

  update;
  delete;

  association _RicefwMaster { with draft; }
}

define behavior for YI_RICEFW_TRANSPORT alias Transport
persistent table yricefw_trsp
draft table yricefw_trsp_d
lock dependent by _RicefwMaster
authorization dependent by _RicefwMaster
etag master LocalLastChangedAt
{
  mapping for yricefw_trsp corresponding
    {
      TransportUUID      = transport_uuid;
      RicefwUUID           = ricefw_uuid;
      TransportType          = transport_type;
      TransportID              = transport_id;
      Description                = description;
      TransportStatus              = transport_status;
      ImportSequence                 = import_sequence;
      ReleasedOn                       = released_on;
      CreatedBy                          = created_by;
      CreatedAt                           = created_at;
      LastChangedBy                         = last_changed_by;
      LocalLastChangedAt                      = local_last_changed_at;
    }

  field ( numbering : managed, readonly ) TransportUUID;
  field ( readonly ) RicefwUUID;
  field ( mandatory ) TransportType, TransportID, TransportStatus;
  field ( readonly ) CreatedBy, CreatedAt, LastChangedBy, LocalLastChangedAt;

  update;
  delete;

  association _RicefwMaster { with draft; }
}
```

### จุดออกแบบที่เลือก

**`numbering : managed`** บน UUID ทุกตัว — RAP สร้าง UUID ให้อัตโนมัติตอน create ไม่ต้องเขียน
determination เอง

**`RicefwUUID` ใน child เป็น `readonly`** — เป็น foreign key ที่ RAP เติมให้เองผ่าน composition
ถ้าปล่อยให้แก้ได้ user จะย้าย child ข้าม parent ได้ซึ่งไม่ควร

**Child ไม่มี `create;` ตรงๆ** — สร้างได้ผ่าน `association _Owner { create; }` ที่ root เท่านั้น
บังคับให้ทุก child ต้องมี parent เสมอ

**`mandatory` ตามที่ตกลง** — root เพิ่ม `DeliveryType` เข้าไปด้วยตามที่คุยกัน (design.md ฉบับแรก
มีแค่ `ricefw_id`/`description`/`ricefw_type` เพราะเขียนก่อนจะแยก `delivery_type` ออกมา)

**`draft action` 5 ตัว** — ชุดมาตรฐานของ draft-enabled BO (`Activate`/`Discard`/`Edit`/`Resume`/`Prepare`)
ต้องประกาศเองใน `strict ( 2 )`

**ยังไม่มี validation/determination** — ตามแผน 5.1 เอาให้ CRUD + draft ทำงานได้ก่อน

---

## 5.2 — Determination `setInitialStatus` ✅

RICEFW ที่สร้างใหม่ได้ `OverallStatus = 'OPN'` (Not Assigned) อัตโนมัติ ไม่ต้องให้ user เลือกเอง

### เพิ่มใน bdef (root block)

```abap
determination setInitialStatus on modify { create; }
```

วางไว้ในกลุ่มเดียวกับ `create; update; delete;` ของ root

### Behavior Pool — method definition (ตามที่ ADT quick-fix generate)

```abap
METHODS setinitialstatus FOR DETERMINE ON MODIFY
  keys FOR ricefwmaster~setinitialstatus.
```

> ⚠️ **ไม่มี `IMPORTING`** — signature ของ `FOR DETERMINE`/`FOR VALIDATE` เป็น syntax เฉพาะ
> ของ RAP ไม่ใช่ method declaration ธรรมดา ยึดตามที่ ADT quick-fix generate ให้เสมอ

### Implementation

```abap
METHOD setInitialStatus.

  MODIFY ENTITIES OF yr_ricefw IN LOCAL MODE
    ENTITY RicefwMaster
      UPDATE FIELDS ( OverallStatus )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                       OverallStatus = 'OPN' ) )
    FAILED   DATA(ls_failed)
    REPORTED DATA(ls_reported).

ENDMETHOD.
```

**`on modify { create; }`** — ทำงานตอน create เท่านั้น ไม่ทำงานตอน update (ถ้า user แก้ status
เป็นอย่างอื่นแล้ว ไม่ควรมีอะไรมาเซ็ตทับกลับ)

**`IN LOCAL MODE`** — determination เรียกจากภายใน framework เดียวกัน ไม่ต้องผ่าน
authorization/determination อื่นซ้ำ จำเป็นมาก เพราะ `UPDATE FIELDS ( OverallStatus )` เอง
จะไป trigger determination ตัวนี้ซ้ำถ้าไม่ใส่ — เสี่ยง infinite loop

---

## 5.3 — Validation `validateRicefwId` ✅

กัน `ricefw_id` ว่างและซ้ำ — เพราะเป็น free text ที่ user กรอกเอง ไม่มี number range คุมให้

### เพิ่มใน bdef (root block)

```abap
validation validateRicefwId on save { create; field RicefwID; }
```

**ต้องผูกเข้า `draft determine action Prepare` ด้วย** ไม่งั้น validation จะรันแค่ตอน
Activate จริง ไม่รันระหว่างที่ user ยังแก้ draft อยู่ (ไม่มี real-time feedback):

```abap
draft determine action Prepare
{
  validation validateRicefwId;
}
```

> ⚠️ พอเพิ่ม validation ตัวใหม่ใน Phase 5.4 ต้องเอามาใส่ใน block นี้ด้วยทุกตัว
> ไม่งั้นจะติด warning *"Validation ... is not assigned to any determine action"* แบบเดียวกัน

### Behavior Pool — method definition (ตามที่ ADT quick-fix generate)

```abap
METHODS validateRicefwId FOR VALIDATE ON SAVE
  keys FOR RicefwMaster~validateRicefwId.
```

### Implementation (ฉบับ activate ผ่านจริง)

```abap
METHOD validateRicefwId.

  READ ENTITIES OF yr_ricefw IN LOCAL MODE
    ENTITY RicefwMaster
      FIELDS ( RicefwID )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_ricefw_master).

  " (1) ห้ามว่าง
  LOOP AT lt_ricefw_master INTO DATA(ls_ricefw_master)
      WHERE RicefwID IS INITIAL.
    APPEND VALUE #( %tky         = ls_ricefw_master-%tky
                     %state_area = 'VALIDATE_RICEFW_ID'
                     %msg = new_message( id       = 'YRICEFW'
                                          number   = '001'
                                          severity = if_abap_behv_message=>severity-error )
                     %element-RicefwID = if_abap_behv=>mk-on )
      TO reported-ricefwmaster.
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

      DATA(lv_dup_in_db) = xsdbool(
        line_exists( lt_db_dup[ ricefw_id = ls_ricefw_master-RicefwID ] ) ).

      DATA(lv_count) = 0.
      LOOP AT lt_check INTO DATA(ls_check_dup)
          WHERE RicefwID = ls_ricefw_master-RicefwID.
        lv_count = lv_count + 1.
      ENDLOOP.
      DATA(lv_dup_in_request) = xsdbool( lv_count > 1 ).

      IF lv_dup_in_db = abap_true OR lv_dup_in_request = abap_true.
        APPEND VALUE #( %tky         = ls_ricefw_master-%tky
                         %state_area = 'VALIDATE_RICEFW_ID'
                         %msg = new_message( id       = 'YRICEFW'
                                              number   = '002'
                                              severity = if_abap_behv_message=>severity-error )
                         %element-RicefwID = if_abap_behv=>mk-on )
          TO reported-ricefwmaster.
        APPEND VALUE #( %tky = ls_ricefw_master-%tky ) TO failed-ricefwmaster.
      ENDIF.

    ENDLOOP.

  ENDIF.

ENDMETHOD.
```

> `%state_area` **อยู่ในโค้ดจริง** (ไม่ได้ตัดออก) — ตอนแรกวินิจฉัยผิดว่า warning เรื่อง hex/X type
> มาจากบรรทัดนี้ ที่จริงมาจาก `%element-RicefwID = abap_true` ต่างหาก (ดูแถวถัดไปในตาราง)
> `%state_area` เป็น string ปกติ ใช้งานได้ถูกต้อง เก็บไว้ตามเดิม

### บทเรียนที่เจอระหว่างทาง (แก้ไปทีละจุด กว่าจะ activate ผ่าน)

| ที่เขียนตอนแรก | ปัญหา | แก้เป็น |
|---|---|---|
| `IMPORTING keys FOR ...` ใน method definition | signature ของ `FOR VALIDATE` ไม่มี `IMPORTING` | ตัด `IMPORTING` ออก — ยึด signature ที่ ADT quick-fix generate |
| `APPEND` ซ้ำ 2 บรรทัดใน loop เดียว | บรรทัดแรกเป็น entry ว่างไม่มี `%msg` — เขียนซ้ำเกินมาตอนร่าง | เหลือ `APPEND` เดียวที่มี `%msg` ครบ |
| `WITH VALUE #( ( %all = if_abap_behv=>mk-on ) )` เพื่ออ่าน "ทุก instance ในรอบ request" | `%all` ไม่มีอยู่จริง | ตัดทิ้ง — ใช้ `lt_ricefw_master`/`lt_check` ที่อ่านจาก `keys` อยู่แล้วแทน เพราะ RAP ส่ง key ทุกตัวในรอบ save มาให้ครั้งเดียว (batch) อยู่แล้ว |
| `FILTER ... USING KEY entity` | สมมติว่ามี secondary key ชื่อ `entity` โดยไม่มีหลักฐาน | ใช้ `LOOP ... WHERE` นับเอาแทน |
| `%element-RicefwID = if_abap_boolean=>true` | interface `IF_ABAP_BOOLEAN` ไม่มีอยู่จริง | เปลี่ยนเป็น `abap_true` (ยังผิดอยู่ — ดูแถวถัดไป) |
| `%element-RicefwID = abap_true` | `%element-<field>` เป็น type `X` (raw byte) ไม่ใช่ `C` — ใส่ char `'X'` แล้วถูกตีความเป็น hex digit ผิด (**นี่คือสาเหตุจริงของ warning "Only characters 0-9..." ไม่ใช่ `%state_area`**) | `if_abap_behv=>mk-on` |
| `draft determine action Prepare;` (บรรทัดเปล่า) | validation ไม่ถูกเรียกระหว่างแก้ draft (แค่ตอน Activate) | ย้าย `validation validateRicefwId;` เข้าไปใน `{ }` ของ `Prepare` |

> ⚠️ **แก้ความเข้าใจ (ดู 5.4)**: ตอนนั้นสรุปว่า "validation ทุกตัวต้องผูกเข้า `Prepare` ไม่งั้น
> warning ค้างตลอด" — ไม่ครบถ้วน ดู 5.4 สำหรับข้อสังเกตที่แก้ไข

---

## 5.4 — Validation `validateDates` และ `validateProgress` ✅

**ตัด `validateOwner` ออกจากแผน** — ซ้ำซ้อนกับ `field ( mandatory ) OwnerID, OwnerName, Role;`
ที่ประกาศไว้แล้วใน Phase 5.1 ซึ่งเป็น validation "ห้ามว่าง" ในตัวอยู่แล้ว ไม่ต้องเขียน custom
validation ซ้ำ

### bdef — เพิ่มใน root block

```abap
validation validateDates on save { create; update; field PlanStart, PlanFinish; }
```

และผูกเข้า `Prepare`:

```abap
draft determine action Prepare
{
  validation validateRicefwId;
  validation validateDates;
}
```

### bdef — เพิ่มใน owner block

```abap
validation validateProgress on save { create; update; field Progress; }
```

**ไม่ได้ผูกเข้า `Prepare`** — ดูข้อสังเกตด้านล่าง

### Behavior Pool — `validateDates` (ใน `LHC_RicefwMaster`)

```abap
METHODS validateDates FOR VALIDATE ON SAVE
  keys FOR RicefwMaster~validateDates.
```

```abap
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
                       %msg = new_message( id       = 'YRICEFW'
                                            number   = '003'
                                            severity = if_abap_behv_message=>severity-error )
                       %element-PlanFinish = if_abap_behv=>mk-on )
        TO reported-ricefwmaster.
      APPEND VALUE #( %tky = ls_ricefw_master-%tky ) TO failed-ricefwmaster.

    ENDIF.

  ENDLOOP.

ENDMETHOD.
```

### Behavior Pool — `validateProgress` (class ใหม่ `LHC_Owner`)

```abap
METHODS validateProgress FOR VALIDATE ON SAVE
  keys FOR Owner~validateProgress.
```

```abap
METHOD validateProgress.

  READ ENTITIES OF yr_ricefw IN LOCAL MODE
    ENTITY Owner
      FIELDS ( Progress )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_owner).

  LOOP AT lt_owner INTO DATA(ls_owner)
      WHERE Progress > 100.
    APPEND VALUE #( %tky = ls_owner-%tky
                     %msg = new_message( id       = 'YRICEFW'
                                          number   = '004'
                                          severity = if_abap_behv_message=>severity-error )
                     %element-Progress = if_abap_behv=>mk-on )
      TO reported-owner.
    APPEND VALUE #( %tky = ls_owner-%tky ) TO failed-owner.
  ENDLOOP.

ENDMETHOD.
```

เช็คแค่ `> 100` ไม่เช็ค `< 0` เพราะ `Progress` เป็น `abap.int1` (**unsigned**, ช่วง 0–255)
ติดลบไม่ได้อยู่แล้วโดยตัว type เอง — เช็ค `< 0` จะเป็นเงื่อนไขที่ไม่มีทางเป็นจริงเลย

### Message Class `YRICEFW` — เพิ่ม

| Number | Text |
|---|---|
| `003` | Plan finish date must not be before plan start date |
| `004` | Progress must not exceed 100 |

### บทเรียนที่เจอระหว่างทาง

| ที่เขียนตอนแรก | ปัญหา | แก้เป็น |
|---|---|---|
| `FIELDS ( PlanStart, PlanFinish )` | EML `FIELDS ( ... )` เว้นวรรคคั่น ไม่ใช่ comma (ต่างจาก `VALUE #`/`SELECT`) — บั๊กนี้ซ่อนได้นานถ้ามี field เดียว | `FIELDS ( PlanStart PlanFinish )` |
| `LOOP ... WHERE PlanFinish < PlanStart` | `LOOP...WHERE` เทียบ component เปล่ากับ component เปล่าอีกตัวในแถวเดียวกันไม่ได้ (parser ไม่รู้ว่าฝั่งขวาอ้างถึงแถวไหน) | เปลี่ยนเป็น `LOOP` ธรรมดา + `IF` ระบุ work area ทั้งสองฝั่ง (`ls_ricefw_master-PlanFinish < ls_ricefw_master-PlanStart`) |

### 💡 ข้อสังเกตเรื่อง `Prepare` — แก้ความเข้าใจจาก 5.3

ตอน 5.3 สรุปว่า "validation ทุกตัวต้องผูกเข้า `Prepare` ไม่งั้น warning ค้างตลอด" — **ไม่ครบถ้วน**

`validateProgress` (อยู่บน entity **child** `Owner`) ติด warning เดียวกัน (*"is not assigned to
any determine action"*) ตอนที่เพิ่ง declare ใน bdef **แต่พอ implement behavior pool method
เสร็จ (สร้าง `LHC_Owner` + เขียน method จริง) warning หายไปเอง โดยไม่ได้ผูกเข้า `Prepare` เลย**

**ข้อสังเกต (ยังไม่ยืนยัน 100%)**: warning นี้อาจเป็นสัญญาณ "ยังไม่มี implementation รองรับ"
มากกว่าจะเป็นกฎตายตัวว่าทุก validation ต้องผูก `Prepare` — หรืออาจเป็นได้ว่า validation ระดับ
**root** (ที่ user แก้ field บน Object Page หลัก) ต้องผูกจริงเพื่อ real-time feedback แต่
validation ระดับ **child** ระบบจัดการให้เองบางส่วน — ไม่ว่าเหตุผลจริงจะเป็นอะไร ผลลัพธ์ที่ได้
คือ activate สะอาด ไม่มี warning ค้าง จึงถือว่าถูกต้องแล้ว

**Trade-off ที่ยอมรับ**: `validateProgress` จะไม่มี real-time feedback ระหว่างแก้ draft
(เห็น error ตอนกด Activate เท่านั้น) — ยอมรับได้สำหรับ demo ถ้าต้องการ real-time จริง
ต้องหา syntax ผูก child validation เข้า `Prepare` ที่ถูกต้องก่อน (ยังไม่ยืนยัน)

---

## Checklist

- [x] `YR_RICEFW` bdef — 4 block (root + 3 child) mass-activate ผ่าน 0 error 0 warning
- [x] Draft tables ครบ 4 ตัว — `invertedIndividualIndex` ครบ (key = `mandt` + uuid = 2 คอลัมน์)
- [x] Behavior pool `YBP_R_RICEFW` + handler classes `LHC_RicefwMaster`, `LHC_Owner`
- [x] `mapping for` ครบทุก entity — แก้ warning เรื่อง field mapping ทั้งหมด
- [x] **5.2** Determination `setInitialStatus` — activate ผ่าน
- [x] **5.3** Validation `validateRicefwId` — activate ผ่าน 0 error 0 warning (ยกเว้น
      authorization warning ที่ตั้งใจเลื่อนไป Phase 9)
- [x] **5.4** Validation `validateDates` `validateProgress` — activate ผ่าน 0 error 0 warning
      (`validateOwner` ตัดออก — ซ้ำซ้อนกับ `field ( mandatory )` จาก 5.1)
- [ ] **5.5** Unique index บน `ricefw_id`
- [ ] Smoke test class `YCL_RICEFW_EML_TEST`
