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

## 5.5 — Unique Index บน `ricefw_id` ✅

Object: **`YRICEFW_HDR~Y01`** (Table Index) — ด่านสุดท้ายที่ database กัน `RICEFW ID` ซ้ำ
เผื่อกรณี race condition ที่ `validateRicefwId` (application layer) หลุดได้ (ดู design.md
เรื่อง "เร็วขึ้น" vs "ถูกต้องเสมอ" — index ตัวนี้เป็นเรื่อง data integrity ไม่ใช่ performance
จึงไม่ใช่ index ที่ถูกยกเลิกไปตอน Phase 2)

### เป็น form editor ไม่ใช่ code-based

ต่างจาก CDS/bdef ที่ผ่านมา — **Table Index เป็น form** (เหมือน Domain/Data Element ตอน
Phase 1) ไม่มี DDL source ให้เขียนเอง

### ขั้นตอนที่ใช้ได้จริง

**1. สร้าง object**: `New → Other ABAP Repository Object` → ค้นหา **"Index"** →
เลือก **"Table Index"** (ไม่ใช่ "Extension Index" ซึ่งมีไว้สำหรับเพิ่ม index ให้ table ที่ไม่ใช่
ของเราเอง)

**2. ตั้งชื่อตาม scheme บังคับ**: `[tablename]~[indexId]`

```
Name: YRICEFW_HDR~Y01
```

ชื่อ table ต้องอยู่ในชื่อ object เลย ไม่มีช่องแยกให้กรอก table ต่างหาก

**3. กรอก form**:
- ✅ ติ๊ก **"Unique Index"**
- ไม่ติ๊ก "Index on Table Buffer only" / "Fuzzy Search Index"
- Index Fields (เรียงตามลำดับนี้):
  1. `CLIENT`
  2. `RICEFW_ID`

### ⚠️ บทเรียน: ชื่อ client field ไม่ใช่ `MANDT` เสมอไป

ตอนแรกลองใส่ `MANDT` (field client มาตรฐานของ SAP) แล้วเจอ error สองชั้น:

```
Index YRICEFW_HDR-Y01 (field MANDT is not in the table)
Index YRICEFW_HDR-Y01 (client field required for unique index)
```

**สาเหตุ**: `MANDT` เป็นชื่อที่เห็นจาก **draft table** (`YRICEFW_HDR_D`) ซึ่งเป็น object ที่
ADT generate เองอัตโนมัติ ใช้ชื่อ field ตามธรรมเนียมของมันเอง — **ไม่เกี่ยวกับ table ต้นทาง
ที่เราเขียน DDL เอง**

ย้อนกลับไปดู DDL ของ `yricefw_hdr` (Phase 2) เราตั้งชื่อ field เองว่า `client` ไม่ใช่ `mandt`:

```abap
key client : abap.clnt not null;
```

พอ activate แล้วชื่อ column จริงในระบบเลยกลายเป็น **`CLIENT`** (ตัวใหญ่ ตามชื่อที่เราตั้งเอง)
ไม่ใช่ `MANDT` — **ชื่อ physical column ตามชื่อที่ตั้งใน DDL source เสมอ ไม่ใช่ตามธรรมเนียม
มาตรฐานของ SAP โดยอัตโนมัติ** ถ้าอยากรู้ชื่อ field จริงของ table ไหน ให้เปิด DDL source ของ
table นั้นดูตรงๆ ดีที่สุด อย่าอ้างอิงจาก draft table หรือ object อื่นที่ generate มา

---

## 5.6 — Smoke Test `YCL_RICEFW_EML_TEST` (EML, Stage 1: root only) ✅

Console class (`IF_OO_ADT_CLASSRUN~MAIN`) ทดสอบ CRUD + validation ของ `YR_RICEFW` ผ่าน EML
โดยตรง (ไม่ผ่าน UI) — ครอบคลุมเฉพาะ root entity ก่อน (deep-create ของ child ทำต่อใน 5.7)

### โครงสร้าง class (ฉบับสุดท้าย — หลัง refactor แยก stage เป็น private method)

แต่ละ stage เป็น private method แยกกัน `MAIN` เหลือแค่ 2 บรรทัด อ่านแล้วเห็นโครงทั้งหมดทันที

```abap
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
```

> ⚠️ **ผลข้างเคียงของ refactor ที่ต้องระวัง**: ตอน Stage 1 อยู่ใน `MAIN` โดยตรง การ `RETURN`
> ที่ error path = จบโปรแกรมเลย ไม่ต้อง `ROLLBACK ENTITIES` ก็ได้ — แต่พอแยกเป็น method
> การ `RETURN` แค่ออกจาก method **แล้ว Stage 2 ยังรันต่อ** ถ้าไม่ rollback ของค้างจาก Stage 1
> จะไปทำ Stage 2 พังตาม (บทเรียนเดิมจากเคส `BAD1` แค่ย้ายบริบท) จึงต้องเพิ่ม
> `ROLLBACK ENTITIES.` ก่อน `RETURN.` ทุกจุดใน `stage1_root_only`

### Source `stage1_root_only` (รันผ่านครบทุกจุด)

```abap
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
        CREATE FIELDS ( RicefwID RicefwType DeliveryType Description
                         PlanStart PlanFinish )
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
```

### Run ผลลัพธ์สุดท้าย (ครบ ไม่มี anomaly)

```
=== RICEFW Smoke Test — Stage 1: root only ===
พบ record เก่าค้างอยู่ 1 รายการ — ลบทั้งหมดก่อนเริ่ม test
ลบ record เก่าทั้งหมดสำเร็จ
--- After CREATE (modify buffer) ---
--- After COMMIT ---
Committed. RicefwUUID = FA163ECED1481FE1A5B29E883DD4FB36
RicefwID = SMOKE-001  OverallStatus = OPN
=== Negative test: empty RicefwID ===
--- After CREATE (modify buffer, ยังไม่ commit) ---
  FAILED entries: 0
  REPORTED entries: 0
  (คาดว่าว่างทั้งคู่ — validation ยังไม่รันจนกว่าจะ commit)
--- After COMMIT (validation ควรรันแล้ว) ---
  FAILED key: FA163ECED1481FE1A5B29E883DD57B36
  REPORTED: RICEFW ID must not be initial
Correctly rejected at COMMIT.
--- Cleanup result ---
Cleanup: test record deleted.
=== Stage 1 Done ===
```

### บทเรียนที่เจอระหว่างทาง

| ที่เขียนตอนแรก | ปัญหา | แก้เป็น |
|---|---|---|
| `DELETE WITH VALUE #( ( %tky = ... ) )` | EML `DELETE` ใช้ `FROM`ไม่ใช่ `WITH` (ต่างจาก `CREATE`/`UPDATE`) — error `"FROM" expected after "DELETE"` | `DELETE FROM VALUE #( ( %tky = ... ) )` |
| เช็ค `FAILED`/`REPORTED` ทันทีหลัง `MODIFY ENTITIES` ของ negative test | **validation ที่ประกาศ `on save` รันตอน `COMMIT ENTITIES` เท่านั้น** — `MODIFY ENTITIES` แค่ใส่ buffer ยังไม่ trigger save sequence เลย เช็คตอนนั้นเลยว่างเปล่าเสมอ ไม่ว่า validation จะถูกหรือผิด | ต้อง `COMMIT ENTITIES` ก่อน แล้วเช็ค `FAILED`/`REPORTED` จาก **ผลของ COMMIT** ไม่ใช่จาก MODIFY |
| ไม่ rollback หลัง commit ที่ fail | record ที่ fail validation (`BAD1`) **ยังค้างอยู่ใน RAP transactional buffer ต่อ** แม้ commit นั้นจะ fail ไปแล้ว — พอเรียก `COMMIT ENTITIES` รอบถัดไป (cleanup) ระบบเอา `BAD1` มา validate ซ้ำ fail ซ้ำอีกรอบ ทำให้ cleanup ถูกรายงานว่า FAILED ทั้งที่การลบ record จริงผ่านไปแล้ว | เรียก `ROLLBACK ENTITIES.` ทันทีหลังยืนยันว่า commit ที่ fail เป็นผลที่ถูกต้องแล้ว (negative test ทำหน้าที่เสร็จ) เพื่อล้าง buffer ก่อนทำ operation ถัดไป |
| `ls_mapped-ricefwmaster[ %cid = 'ROOT1' ]` (table expression ไม่ระบุ key) | compiler warning: *"An initial part of the secondary key 'CID' with type SORTED is covered. However, 'CID' is not used in the statement."* — type ของ `MAPPED-ricefwmaster` มี secondary key ชื่อ `cid` อยู่แล้ว แต่ไม่ได้สั่งใช้ตรงๆ (เป็นแค่ performance hint ไม่ใช่ error) | `ls_mapped-ricefwmaster[ KEY cid COMPONENTS %cid = 'ROOT1' ]` — ระบุ key ให้ชัดเจน |
| รัน test ซ้ำโดยไม่เคลียร์ record เก่าก่อน | `RicefwID = 'SMOKE-001'` ค้างจาก run ก่อนหน้า (เพราะ cleanup เคย fail) ทำให้ CREATE รอบใหม่ชน `validateRicefwId` duplicate check | เพิ่ม step 0: `SELECT` หา UUID ทุก record ที่ค้างจาก `YR_RICEFW` (business-key lookup ต้องใช้ SELECT ธรรมดา เพราะ `READ ENTITIES` อ้างด้วย `%tky` เท่านั้น) แล้วลบทั้งหมดแบบ batch (`FOR ... IN ... ( ... )` ใน `VALUE #`) ก่อนเริ่ม test — ทำให้ script idempotent รันซ้ำกี่ครั้งก็ได้ |

### 💡 ข้อสรุปสำคัญ: `on save` = ช่วง `COMMIT ENTITIES` ไม่ใช่ `MODIFY ENTITIES`

`MODIFY ENTITIES` มีหน้าที่แค่ใส่ข้อมูลเข้า **transactional buffer ในหน่วยความจำ** เท่านั้น
ไม่ trigger `determination`/`validation` ที่ประกาศเป็น `on save` เลย — พวกนี้จะรันจริงตอน
`COMMIT ENTITIES` (ช่วง "save sequence") เท่านั้น ผลตามมา 2 อย่างที่ต้องจำ:

1. จะเช็คว่า validation reject หรือไม่ ต้อง `COMMIT ENTITIES` ก่อนเสมอ เช็คจาก `MODIFY` เพียว ๆ
   จะได้ผลลัพธ์ว่างเปล่าเสมอไม่ว่า input จะถูกหรือผิด
2. commit ที่ fail ไม่ได้ clear ตัวเองออกจาก buffer อัตโนมัติ (เพื่อรองรับ use case จริงของ
   Fiori ที่ draft ต้องค้างให้ user แก้ต่อได้) — ถ้าไม่ต้องการ retry ต้องสั่ง `ROLLBACK ENTITIES`
   เอง ไม่งั้น record ที่ fail จะถูกเอามา re-validate ซ้ำในทุก `COMMIT ENTITIES` ถัดไปในรอบ
   เดียวกัน

### Checklist Stage 1

- [x] CREATE root entity (ไม่มี child)
- [x] COMMIT — ยืนยัน `setInitialStatus` ทำงานจริงผ่าน EML (`OverallStatus = OPN`)
- [x] READ ENTITIES กลับมาเช็คค่า
- [x] Negative test — `validateRicefwId` reject ค่าว่างถูกต้อง (ยืนยันผ่าน COMMIT ไม่ใช่ MODIFY)
- [x] `ROLLBACK ENTITIES` เคลียร์ buffer หลัง commit ที่ fail
- [x] DELETE + COMMIT cleanup — idempotent รันซ้ำได้เรื่อย ๆ

---

## 5.7 — Smoke Test Stage 2: Deep-create (root + Owner child ในคำสั่งเดียว) ✅

เพิ่ม private method `stage2_deep_create` ใน `YCL_RICEFW_EML_TEST` เรียกต่อจาก Stage 1
ใน `MAIN` — ทดสอบสร้าง root + child `Owner` ผ่าน **`MODIFY ENTITIES` คำสั่งเดียว** (ไม่ใช่
commit แยกกัน) เพื่อพิสูจน์ true deep-create ที่เป็นเป้าหมายเดิมของ Stage 2

### 💡 ข้อค้นพบสำคัญที่สุดของ session: โครงสร้าง `CREATE BY \_Assoc` เป็น 2 ชั้น ไม่ใช่ flat

ตอนแรกเขียน field ของ child (`OwnerID` ฯลฯ) เป็น named component ระดับเดียวกับ `%cid_ref`
โดยตรง — activate ผ่าน (ADT ไม่ error ตอนนั้นเพราะยังไม่เจอ field จริง) แต่พอ error ขึ้นจริง
กลับพบว่า **field ธุรกิจของ child ไม่ได้อยู่ระดับเดียวกับ `%cid_ref`/`%tky`** ต้องเข้าไปอยู่ใน
sub-structure ชื่อ **`%target`** อีกชั้นหนึ่ง:

```abap
" ผิด — field ของ child (OwnerID ฯลฯ) แบนราบกับ %cid_ref
CREATE BY \_Owner
  FIELDS ( OwnerID OwnerName Role Progress )
  WITH VALUE #( ( %cid_ref  = 'ROOT2'
                   OwnerID   = 'OWN-001'    " ❌ No component exists with the name "OWNERID"
                   ... ) )

" ถูก — field ของ child ต้องอยู่ใน %target (internal table ซ้อนอีกชั้น)
CREATE BY \_Owner
  FIELDS ( OwnerID OwnerName Role Progress )
  WITH VALUE #( ( %cid_ref = 'ROOT2'                    " ชั้นนอก = ระบุ parent
                   %target  = VALUE #( ( %cid      = 'OWNER1'   " ชั้นใน = field ของ child
                                          OwnerID   = 'OWN-001'
                                          OwnerName = 'Somchai Test'
                                          Role      = 'PM'
                                          Progress  = 0 ) ) ) )
```

**โครงสร้าง**:
- **ชั้นนอก** (row ของ `CREATE BY \_Assoc`) มีแค่ meta field สำหรับระบุ parent เท่านั้น:
  `%cid_ref` (parent ยังไม่ commit ในคำสั่งเดียวกัน — อ้างผ่าน `%cid`) หรือ `%tky`
  (parent commit ไปแล้วจริง มี key จริง) — **ไม่มี `%cid` ของตัวเองที่ชั้นนี้**
- **`%target`** = internal table ของ instance ที่จะสร้างจริง (รองรับสร้างหลาย child
  ในคำสั่งเดียวได้ — เป็น table ไม่ใช่ structure เดี่ยว) — field ธุรกิจทั้งหมดของ child
  รวมถึง `%cid` ของ child เอง (ถ้าต้องการอ้างอิงผ่าน `MAPPED` ทีหลัง) อยู่ **ในนี้**

**วิธีที่เจอ**: กด Ctrl+Space ที่ตำแหน่ง row ของ `CREATE BY \_Owner` แล้วเห็น component
list จริง (`%cid_ref` `%is_draft` `%key` `%pky` `%target` `%tky`) — ไม่มี field ธุรกิจให้เลือก
เลยสักตัว จุดนี้เป็นเบาะแสว่าต้องมีอีกชั้นซ่อนอยู่ ลองใช้ `%target` ตามที่เห็นใน list แล้ว
activate ผ่านทันที (ก่อนหน้านั้นเดาผิดไป 2 รอบ: ลองใส่ `%cid` ตรงๆ ที่ชั้นนอก — ไม่มีอยู่จริง
เดาว่า parenthesis หลุด — ไม่ใช่สาเหตุจริง)

**Root ก็ใช้ pattern เดียวกันตอนอ้างถึง parent ที่ commit แล้ว**: เปลี่ยนจาก
`%cid_ref = 'ROOT2'` เป็น `%tky = ls_root_key` ถ้า parent มี key จริงแล้ว (ทดสอบแยกไว้ก่อน
ระหว่างที่ยังไม่รู้เรื่อง `%target` — ดูหัวข้อถัดไป)

### bdef ไม่ต้องแก้อะไรเลย — `%target` เป็นเรื่องของ syntax EML ล้วน ๆ

ไม่ต้องเพิ่ม/แก้ annotation หรือ association ใน `YR_RICEFW` bdef ที่มีอยู่แล้วเลย
`CREATE BY \_Owner` ใช้ association `_Owner { create; with draft; }` ที่ประกาศไว้ตั้งแต่ 5.1
ได้ทันที — เป็นแค่เรื่อง EML statement syntax ฝั่ง console class เท่านั้น

### Source `stage2_deep_create` (declaration ดูที่ §5.6 — โครงสร้าง class)

```abap
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
      CREATE FIELDS ( RicefwID RicefwType DeliveryType Description
                       PlanStart PlanFinish )
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
```

### Run ผลลัพธ์สุดท้าย (ครบ ไม่มี anomaly)

```
=== RICEFW Smoke Test — Stage 2: deep-create (root + Owner ในคำสั่งเดียว) ===
--- After deep CREATE (modify buffer) ---
  FAILED root entries: 0
  FAILED owner entries: 0
--- After COMMIT ---
  FAILED root entries: 0
  FAILED owner entries: 0
Committed. Root RicefwUUID = FA163ECED1481FE1A5B3CA3DF9A5FB36
            Owner OwnerUUID = FA163ECED1481FE1A5B3CA3DF9A61B36
Owner: OwnerID = OWN-001  Name = Somchai Test  Role = PM
  RicefwUUID ตรงกับ root — composition เติม FK ให้ถูกต้อง
--- Cleanup result ---
Cleanup: root deleted.
Cascade delete ทำงานถูกต้อง — Owner child ถูกลบตาม root ไปด้วย
=== Stage 2 Done ===
```

ยืนยันครบทุกจุด: deep-create atomic ในคำสั่งเดียว, `%cid`/`%cid_ref` resolve ข้าม entity
ถูกต้อง, FK (`RicefwUUID`) auto-fill ผ่าน composition ถูกต้อง, cascade delete ทำงานจริง
ที่ระดับ database (ไม่ใช่แค่ผ่าน CDS view)

### Checklist Stage 1 + 2

- [x] **Stage 1**: CREATE root entity (ไม่มี child)
- [x] COMMIT — ยืนยัน `setInitialStatus` ทำงานจริงผ่าน EML (`OverallStatus = OPN`)
- [x] READ ENTITIES กลับมาเช็คค่า
- [x] Negative test — `validateRicefwId` reject ค่าว่างถูกต้อง (ยืนยันผ่าน COMMIT ไม่ใช่ MODIFY)
- [x] `ROLLBACK ENTITIES` เคลียร์ buffer หลัง commit ที่ fail
- [x] DELETE + COMMIT cleanup — idempotent รันซ้ำได้เรื่อย ๆ
- [x] **Stage 2**: Deep-create root + Owner child ในคำสั่งเดียว — ค้นพบ pattern `%target`
- [x] ยืนยัน FK (`RicefwUUID`) auto-fill ถูกต้องผ่าน composition
- [x] ยืนยัน cascade delete ทำงานจริงที่ระดับ database

**Smoke test ทั้ง 2 stage เสร็จสมบูรณ์ ✅ — พร้อมไป Phase 6**

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
- [x] **5.5** Unique index `YRICEFW_HDR~Y01` บน (`CLIENT`, `RICEFW_ID`) — activate ผ่าน
- [x] **5.6** Smoke test class `YCL_RICEFW_EML_TEST` (Stage 1: root only) — รันผ่านครบทุกจุด
      ยืนยัน CRUD, determination, validation ทำงานจริงผ่าน EML
- [x] **5.7** Smoke test Stage 2 — deep-create root + Owner child ในคำสั่งเดียว รันผ่านครบทุกจุด
      ค้นพบ pattern `%target` สำหรับ nested create ผ่าน composition association

**Phase 5 จบแล้ว ✅**
