# Phase 2 — Database Tables (Spec) ✅

Package: `YRICEFW` · ABAP for Cloud Development

**4 transaction tables** — activate ผ่านครบทั้งหมด 0 errors 0 warnings

---

## ⚠️ Annotation ที่ต้องมีทุก table: `invertedIndividualIndex`

```abap
@AbapCatalog.primaryKey.invertedIndividualIndex : true
```

**ถ้าไม่ใส่จะติด warning:** *"Key must have the type Inverted Individual on the database"*

**กฎ: ขึ้นกับ *จำนวน* key field ไม่ใช่ชนิดข้อมูล** — key 2 คอลัมน์ต้องใส่ · 3 คอลัมน์ขึ้นไปไม่ต้อง

table ทั้ง 4 ตัวมี key = `client` + `*_uuid` = 2 คอลัมน์ จึงต้องใส่ทุกตัว

**เหตุผล**: index แบบ **Inverted Value** (default) สร้างคอลัมน์ภายในเพิ่มที่เก็บ key
ทุกคอลัมน์ต่อกัน ถ้า key มีแค่ `client` (แทบเป็นค่าเดียวทั้ง table) + คอลัมน์จริง 1 ตัว
คอลัมน์ที่ต่อกันนั้นแทบไม่ต่างจากคอลัมน์เดียว → เปลืองเปล่า
HANA จึงแนะนำ **Inverted Individual** (index แยกทีละคอลัมน์) แทน

> รายละเอียดพร้อมหลักฐานจาก 11 table อยู่ใน `phase3_spec.md` §2.1

> Quick Fix ของ ADT ไม่มีตัวเลือกให้แก้ warning นี้ ต้องพิมพ์ annotation เอง

---

## 1. `YRICEFW_HDR` — RICEFW Master

```abap
@EndUserText.label : 'RICEFW Master'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_hdr {

  key client            : abap.clnt not null;
  key ricefw_uuid       : sysuuid_x16 not null;

  ricefw_id             : ye_ricefw_id;
  ricefw_type           : ye_ricefw_type;
  delivery_type         : ye_delivery_type;
  description           : abap.char(80);
  overall_status        : ye_overall_status;
  plan_start            : abap.datn;
  plan_finish           : abap.datn;
  remark                : abap.string(0);

  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;

}
```

## 2. `YRICEFW_OWNER` — RICEFW Owner

```abap
@EndUserText.label : 'RICEFW Owner'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_owner {

  key client            : abap.clnt not null;
  key owner_uuid        : sysuuid_x16 not null;

  ricefw_uuid           : sysuuid_x16;

  owner_id              : vdm_userid;
  owner_name            : vdm_userdescription;
  role                  : ye_role;
  progress              : abap.int1;

  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;

}
```

## 3. `YRICEFW_OBJ` — RICEFW Object

```abap
@EndUserText.label : 'RICEFW Object'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_obj {

  key client            : abap.clnt not null;
  key object_uuid       : sysuuid_x16 not null;

  ricefw_uuid           : sysuuid_x16;

  object_name           : abap.char(40);
  object_type           : ye_object_type;
  description           : abap.char(80);

  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;

}
```

---

## หมายเหตุการออกแบบ

**Admin field ต่างกันระหว่าง root กับ child — ตั้งใจ**

| Field | Root | Child | หน้าที่ |
|-------|------|-------|--------|
| `local_last_changed_at` | ✅ | ✅ | **ETag master** ของ instance นั้นๆ — RAP บังคับทุก entity |
| `last_changed_at` | ✅ | ❌ | **Total ETag** เปลี่ยนเมื่อ child เปลี่ยนด้วย มีที่ root เท่านั้น |

**ไม่มี foreign key ที่ระดับ DDIC** — `ricefw_uuid` ใน child เป็น field ธรรมดา
RAP จัดการความสัมพันธ์ผ่าน `composition` ใน CDS และ cascade delete ให้เอง
ถ้าใส่ FK ที่ DDIC ด้วยจะไปชนกับ draft handling

**`remark` เป็น `abap.string(0)` → LOB บน HANA (NCLOB)**
ยาวไม่จำกัด แต่ทำ index ไม่ได้ และใช้ใน `WHERE` / `ORDER BY` ไม่ได้
เหมาะกับช่องหมายเหตุที่แสดงทีละ record ถ้าวันหนึ่งอยากค้นหาข้อความใน remark
ต้องเปลี่ยนเป็น `abap.char(255)`

**`vdm_userid` / `vdm_userdescription`** — ใช้ได้บน ABAP for Cloud Development ✅
(activate ผ่านแล้ว ไม่ติด released-object check)

## 4. `YRICEFW_TRSP` — RICEFW Transport ✅

เก็บ Transport Request / Software Collection ที่เกี่ยวข้องกับ RICEFW แต่ละรายการ
ออกแบบให้ใช้ได้ทั้ง **S/4HANA Cloud Private Edition** และ **Public Edition** — ดูเหตุผลใน `phase3_spec.md` §8

```abap
@EndUserText.label : 'RICEFW Transport'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_trsp {

  key client            : abap.clnt not null;
  key transport_uuid    : sysuuid_x16 not null;

  ricefw_uuid           : sysuuid_x16;

  transport_type        : ye_transport_type;
  transport_id          : ye_transport_id;
  description           : abap.char(80);
  transport_status      : ye_transport_status;
  import_sequence       : abap.int2;
  released_on           : abap.datn;

  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;

}
```

**เหตุผลของ field ที่ไม่ธรรมดา**

| Field | ทำไมต้องมี |
|-------|-----------|
| `transport_id` CHAR 40 | TR ยาว 10 ตัว (`S4DK900123`) แต่ Software Collection ตั้งชื่อเองยาวกว่า — 40 ครอบคลุมทั้งคู่ **ไม่ใช้ `TRKORR`** เพราะสื่อว่าเป็น TR อย่างเดียว และอาจไม่ released บน Public Edition |
| `import_sequence` | RICEFW หนึ่งตัวมักกิน 2–3 TR ที่ต้อง import **ตามลำดับ** ไม่งั้น activate ไม่ผ่าน — เป็นข้อมูลที่หายบ่อยที่สุดตอนส่งมอบ |
| `released_on` | ไล่ย้อนได้ว่าของขึ้นระบบวันไหน ตอบคำถาม "ทำไม PRD ยังไม่มี" |

**ไม่มี `target_system`** — PCE ใช้ SID (`S4Q`/`S4P`) ส่วน Public Edition ไม่มีแนวคิดนี้
ถ้าใส่จะต้องออกแบบต่างกันต่อ edition ซึ่งขัดกับเป้าหมาย · `transport_status` บอกได้อยู่แล้วว่าไปถึงไหน

**เป็น child ของ `YRICEFW_HDR`** — มี `local_last_changed_at` อย่างเดียว ไม่มี `last_changed_at`

---

## ✅ ตัดสินใจ: ไม่สร้าง secondary index

แผนเดิมจะสร้าง 3 index — ทบทวนแล้ว**ยกเลิก 2 ตัว เลื่อน 1 ตัว**

| Index ที่เคยวางแผน | วัตถุประสงค์ | ผล |
|---|---|---|
| (`client`, `ricefw_uuid`) บน `YRICEFW_OWNER` | หา child จาก parent | ❌ **ยกเลิก** |
| (`client`, `ricefw_uuid`) บน `YRICEFW_OBJ` | เหมือนกัน | ❌ **ยกเลิก** |
| (`client`, `ricefw_id`) unique บน `YRICEFW_HDR` | บังคับไม่ให้ ID ซ้ำ | ⏸️ **เลื่อนไป Phase 5** |

**เหตุผลที่ยกเลิก 2 ตัวแรก**: SAP HANA เป็น column store สแกนคอลัมน์เร็วโดยธรรมชาติ
SAP แนะนำไม่ให้สร้าง secondary index เว้นแต่พิสูจน์ได้ว่ามีปัญหา performance จริง
เพราะ index กินหน่วยความจำและทำให้ insert/update ช้าลง — แผนเดิมคิดแบบ row-store database

**เหตุผลที่เลื่อนตัวที่ 3**: unique index ห้าม `ricefw_id` ซ้ำ **รวมถึงค่าว่างซ้ำกัน**
ตอนนี้ยังไม่มี validation ห้ามค่าว่าง (จะทำใน Phase 5) ถ้าสร้าง index ตอนนี้แล้วใส่ test data
ระหว่างพัฒนา Phase 4 จะเจอ short dump แทน error message → ทำพร้อม `validateRicefwId` ใน Phase 5

> ยังไม่ได้ยืนยัน syntax ของการนิยาม index แบบ source-based ใน ABAP Cloud
> (หาในเอกสาร SAP ไม่เจอ) — ตอนถึง Phase 5 ให้ใช้ `New → Other → ABAP Repository Object`
> แล้วค้นคำว่า "index" เพื่อให้ ADT generate template ให้

## Checklist

- [x] `YRICEFW_HDR`
- [x] `YRICEFW_OWNER`
- [x] `YRICEFW_OBJ`
- [x] `YRICEFW_TRSP`
- [x] Activate ครบ 4 ตัว 0 errors 0 warnings
- [x] ~~Index~~ — ยกเลิก 2 เลื่อน 1 (ดูด้านบน)

**Phase 2 จบแล้ว ✅** *(ยกเว้น `YRICEFW_TRSP` ที่เพิ่มเข้ามาทีหลังตอน Phase 3)*
