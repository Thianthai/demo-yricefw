# RICEFW Management — Design Document

> สถานะ: **Design only** — ยังไม่ implement

---

## 1. Naming Convention

### 1.1 CDS / Behavior (ตามที่กำหนด)

| Layer | Prefix | Object |
|-------|--------|--------|
| Interface View (child entities) | `YI_RICEFW_*` | `YI_RICEFW_OWNER`, `YI_RICEFW_OBJECT`, `YI_RICEFW_TRANSPORT` |
| Root View Entity | `YR_RICEFW*` | `YR_RICEFW` |
| Consumption / Projection View | `YC_RICEFW*` | `YC_RICEFW`, `YC_RICEFW_OWNER`, `YC_RICEFW_OBJECT`, `YC_RICEFW_TRANSPORT` |
| Behavior Definition | `YR_RICEFW*` | `YR_RICEFW` (ชื่อเดียวกับ root view — บังคับโดย RAP) |
| Behavior Projection | `YC_RICEFW*` | `YC_RICEFW` (ชื่อเดียวกับ projection view — บังคับโดย RAP) |
| Metadata Extension | `YC_RICEFW*` | `YC_RICEFW`, `YC_RICEFW_OWNER`, `YC_RICEFW_OBJECT`, `YC_RICEFW_TRANSPORT` |

**หมายเหตุการแบ่ง `YI_` vs `YR_`**
ใน RAP, root entity ของ composition tree ใช้ `YR_` ส่วน child entity ใช้ `YI_`
เป็น convention เดียวกับที่ SAP ใช้ใน ABAP Flight Reference Scenario — ทำให้เห็นจากชื่อทันทีว่า
entity ไหนเป็น root และ entity ไหนต้องเข้าถึงผ่าน parent เท่านั้น

**หมายเหตุ Metadata Extension**
DDLX (metadata extension) กับ DDLS (CDS view) อยู่คนละ object type จึงตั้งชื่อซ้ำกันได้
ถ้าระบบไม่ยอมให้ activate ให้เติม suffix `_MDE` แทน เช่น `YC_RICEFW_MDE`

### 1.2 Service Definition & Service Binding — แนวทางที่แนะนำ

SAP แบ่ง service ออกเป็น 2 กลุ่มตาม **ผู้ใช้ปลายทาง** ไม่ใช่ตาม CDS layer:

| ประเภท | Prefix | ใช้เมื่อ |
|--------|--------|---------|
| **UI Service** | `YUI_*` | Fiori Elements / Freestyle UI5 consume |
| **API Service** | `YAPI_*` | ระบบภายนอกเรียกเข้ามา (integration) |

Service Binding เติม suffix บอก protocol:

| Suffix | ความหมาย |
|--------|----------|
| `_O4` | OData V4 |
| `_O2` | OData V2 |
| `_RS` | Web API (RESTful) |

**สรุปชื่อที่แนะนำสำหรับ project นี้**

| Object | Name | Description |
|--------|------|-------------|
| Service Definition | `YUI_RICEFW` | RICEFW Management UI Service |
| Service Binding | `YUI_RICEFW_O4` | OData V4 — UI |

เหตุผลที่เลือก `YUI_` ไม่ใช่ `YC_`:
- Service ไม่ใช่ CDS view — การใช้ prefix เดียวกันจะทำให้ค้นหาใน ADT สับสน
- ถ้าอนาคตต้องเปิด API ให้ระบบอื่นเรียก จะเพิ่ม `YAPI_RICEFW` + `YAPI_RICEFW_O4` ได้ทันที
  โดยใช้ CDS layer เดิม แค่คนละ service definition
- ตรงกับที่ ADT RAP Generator สร้างให้เป็น default

---

## 2. Data Model

### 2.1 ตอบคำถาม: link ด้วย `ricefw_id` หรือ UUID?

**ตอบ: ใช้ UUID (`sysuuid_x16`) เป็น technical key และ foreign key ระหว่าง table**
ส่วน `ricefw_id` เก็บไว้เป็น **semantic key** สำหรับให้คนอ่าน (unique index)

เหตุผล — ยิ่งชัดขึ้นเมื่อ `ricefw_id` เป็น **free text ที่ user กรอกเอง** (ยืนยันแล้ว):

| # | เหตุผล |
|---|--------|
| 1 | **User แก้ ID ได้** — free text แปลว่า user เปลี่ยนค่าได้ตลอด ถ้าใช้เป็น FK จะต้อง cascade update ไปทุก child |
| 2 | **Draft** — RAP draft ต้องการ key ที่นิ่ง ถ้า user แก้ `ricefw_id` ระหว่าง draft จะทำให้ draft/active mapping พัง |
| 3 | **Create ตอนยังว่าง** — ตอนกด Create `ricefw_id` ยังว่างอยู่ (รอ user พิมพ์) แต่ RAP ต้องมี key ตั้งแต่ instance เกิด — key ว่างไม่ได้ |
| 4 | **Child key สั้น** — ถ้าใช้ `ricefw_id` เป็น FK, child ต้องพ่วง key ยาวขึ้นเรื่อยๆ; UUID เป็น key เดี่ยวเสมอ |
| 5 | **ETag / Numbering** — RAP managed with early numbering (UUID) เป็น pattern มาตรฐานที่ SAP แนะนำ |

**Relationship**

```
YRICEFW_HDR.ricefw_uuid  (key)
        │
        ├──< YRICEFW_OWNER.ricefw_uuid   (parent FK)  key = owner_uuid
        ├──< YRICEFW_OBJ.ricefw_uuid     (parent FK)  key = object_uuid
        └──< YRICEFW_TRSP.ricefw_uuid    (parent FK)  key = transport_uuid
```

### 2.2 Table 1 — `YRICEFW_HDR` (RICEFW Master)

- Delivery class: `A` (Application table)
- Data maintenance: `Restriction` (ไม่ให้แก้ผ่าน SM30)

| Key | Field | Type | Description |
|-----|-------|------|-------------|
| ✅ | `client` | `abap.clnt` | Client |
| ✅ | `ricefw_uuid` | `sysuuid_x16` | Technical key |
| | `ricefw_id` | `ye_ricefw_id` | RICEFW ID — **free text CHAR 20, user กรอกเอง** (semantic key, unique index, mandatory) |
| | `ricefw_type` | `ye_ricefw_type` | ประเภท RICEFW — `RPT` `INTF` `CONV` `ENH` `FORM` `WF` |
| | `delivery_type` | `ye_delivery_type` | แนวทางส่งมอบ — `NEW` `LS` `REM` |
| | `description` | `abap.char(80)` | Description |
| | `overall_status` | `ye_overall_status` | Overall status |
| | `plan_start` | `abap.datn` | Planned start date |
| | `plan_finish` | `abap.datn` | Planned finish date |
| | `remark` | `abap.string(0)` | Remark |
| | `created_by` | `abp_creation_user` | |
| | `created_at` | `abp_creation_tstmpl` | |
| | `last_changed_by` | `abp_lastchange_user` | |
| | `last_changed_at` | `abp_lastchange_tstmpl` | **Total ETag** (เปลี่ยนเมื่อ child เปลี่ยนด้วย) |
| | `local_last_changed_at` | `abp_locinst_lastchange_tstmpl` | **ETag master** ของ root เอง |

> ⚠️ `local_last_changed_at` เป็น field ที่เพิ่มจาก list เดิม — RAP managed **บังคับต้องมี**
> ถ้าไม่มี จะทำ optimistic concurrency control ไม่ได้ และ activate behavior definition ไม่ผ่าน

**Index**: `Y01` unique on (`client`, `ricefw_id`)

> ⚠️ `ricefw_id` เป็น free text ที่ user กรอก → **ไม่มี number range**
> ต้องมี validation ใน behavior pool ตรวจ 2 อย่าง: (1) ไม่ว่าง (2) ไม่ซ้ำกับ instance อื่น
> unique index เป็นด่านสุดท้ายที่ DB — แต่ถ้าปล่อยให้ชนที่ DB จะได้ short dump แทน error message สวยๆ บน UI

### 2.3 Table 2 — `YRICEFW_OWNER` (RICEFW Owner)

| Key | Field | Type | Description |
|-----|-------|------|-------------|
| ✅ | `client` | `abap.clnt` | |
| ✅ | `owner_uuid` | `sysuuid_x16` | Technical key |
| | `ricefw_uuid` | `sysuuid_x16` | Parent key → `YRICEFW_HDR` |
| | `owner_id` | `vdm_userid` | User ID |
| | `owner_name` | `vdm_userdescription` | User name (denormalized) |
| | `role` | `ye_role` | Role in RICEFW |
| | `progress` | `abap.int1` | Progress % (0–100) |
| | `created_by` | `abp_creation_user` | |
| | `created_at` | `abp_creation_tstmpl` | |
| | `last_changed_by` | `abp_lastchange_user` | |
| | `local_last_changed_at` | `abp_locinst_lastchange_tstmpl` | ETag master |

> ✅ **`owner_name` — ตัดสินใจแล้ว: เก็บใน table และให้ user พิมพ์เอง** (ไม่ใช่ determination auto-fill)
> เหตุผล: บาง owner อาจไม่มี user master ในระบบ (external consultant, vendor) หรือ user อยากใส่ชื่อในรูปแบบของตัวเอง
>
> **Option เผื่อ upgrade ภายหลัง** — เตรียมไว้แต่ยังไม่เปิดใช้ใน Phase นี้:
> ใน `YI_RICEFW_OWNER` ให้ประกาศ association `_User : association [0..1] to I_User on $projection.owner_id = _User.UserID` ไว้เลยตั้งแต่แรก
> แต่ยังไม่ expose field จาก association ออก UI — วันที่อยากอัปเกรดค่อยเลือกทำอย่างใดอย่างหนึ่ง:
> - เปิด value help บน `owner_id` จาก `I_User` แล้วใช้ determination เติม `owner_name` ให้อัตโนมัติ (user แก้ทับได้)
> - หรือเพิ่ม virtual field `UserNameFromMaster` โชว์คู่กันเพื่อให้เห็นว่าตรงกับ master data ไหม
>
> การประกาศ association ทิ้งไว้ไม่มี cost ตอน runtime ถ้าไม่มีใคร select ผ่านมัน

> 💡 `progress` เป็น `abap.int1` = 0–255 → ต้องมี validation บังคับช่วง 0–100

**Index**: non-unique on (`client`, `ricefw_uuid`)

### 2.4 Table 3 — `YRICEFW_OBJ` (RICEFW Object)

| Key | Field | Type | Description |
|-----|-------|------|-------------|
| ✅ | `client` | `abap.clnt` | |
| ✅ | `object_uuid` | `sysuuid_x16` | Technical key |
| | `ricefw_uuid` | `sysuuid_x16` | Parent key → `YRICEFW_HDR` |
| | `object_name` | `abap.char(40)` | Object name |
| | `object_type` | `ye_object_type` | CLAS / PROG / TABL / DDLS / … |
| | `description` | `abap.char(80)` | Description |
| | `created_by` | `abp_creation_user` | |
| | `created_at` | `abp_creation_tstmpl` | |
| | `last_changed_by` | `abp_lastchange_user` | |
| | `local_last_changed_at` | `abp_locinst_lastchange_tstmpl` | ETag master |

**Index**: non-unique on (`client`, `ricefw_uuid`)

### 2.5 Table 4 — `YRICEFW_TRSP` (RICEFW Transport)

เก็บ Transport Request / Software Collection ที่เกี่ยวข้องกับ RICEFW แต่ละรายการ
ออกแบบให้ใช้ได้ทั้ง Private Edition และ Public Edition — ดูเหตุผลเต็มใน `phase3_spec.md` §8

| Key | Field | Type | Description |
|-----|-------|------|-------------|
| ✅ | `client` | `abap.clnt` | |
| ✅ | `transport_uuid` | `sysuuid_x16` | Technical key |
| | `ricefw_uuid` | `sysuuid_x16` | Parent key → `YRICEFW_HDR` |
| | `transport_type` | `ye_transport_type` | `WB` `CUS` `TOC` `SC` — discriminator ที่ทำให้รองรับ 2 edition |
| | `transport_id` | `ye_transport_id` | CHAR 40 — เลข TR หรือชื่อ Software Collection |
| | `description` | `abap.char(80)` | |
| | `transport_status` | `ye_transport_status` | `MOD` `REL` `IMP` `ERR` |
| | `import_sequence` | `abap.int2` | ลำดับที่ต้อง import |
| | `released_on` | `abap.datn` | วันที่ release |
| | admin fields | `abp_*` | มี `local_last_changed_at` อย่างเดียว (เป็น child) |

### 2.6 Draft Tables

Draft-enabled BO ต้องมี draft table 1 ตัวต่อ 1 entity (ADT generate ให้อัตโนมัติจาก bdef)

| Active table | Draft table |
|--------------|-------------|
| `YRICEFW_HDR` | `YRICEFW_HDR_D` |
| `YRICEFW_OWNER` | `YRICEFW_OWNR_D` |
| `YRICEFW_OBJ` | `YRICEFW_OBJ_D` |
| `YRICEFW_TRSP` | `YRICEFW_TRSP_D` |

> ชื่อ transparent table จำกัด 16 ตัวอักษร — `YRICEFW_OWNER_D` = 15 ตัว ผ่าน แต่ย่อเป็น `YRICEFW_OWNR_D` เพื่อความสม่ำเสมอ

---

## 3. Domains & Data Elements

### 3.1 Domains — ✅ สร้างแล้ว (Phase 1)

| Domain | Description | Data Type | Length | Output Len | Case-sensitive | Fixed Values |
|--------|-------------|-----------|--------|-----------|----------------|--------------|
| `YD_RICEFW_ID` | RICEFW ID | CHAR | 20 | 20 | ❌ | — |
| `YD_RICEFW_TYPE` | RICEFW Type | CHAR | 6 | 6 | ❌ | — |
| `YD_OVERALL_STATUS` | Overall Status | CHAR | 3 | 3 | ❌ | — |
| `YD_ROLE` | Role | CHAR | 2 | 2 | ❌ | — |
| `YD_OBJECT_TYPE` | Object Type | CHAR | 4 | 4 | ❌ | — |

Package: `YRICEFW` (flat — ดู §4)

> **Case-sensitive ไม่ติ๊กทุกตัว = ถูกต้อง** — ADT ใช้คำว่า "Case-sensitive" ซึ่งกลับด้านกับ
> "Lower Case" ใน SE11 เดิม ไม่ติ๊ก = บังคับ uppercase ตามที่ออกแบบไว้

> ⚠️ Length ในตารางนี้อ่านจาก screenshot รอบก่อนหน้า (ตอนยังใช้ชื่อ `YD_WRICEF_*`)
> ถ้าตอน rename มีการแก้ length ด้วย รบกวนแจ้งเพื่อ sync เอกสาร

### 3.2 ตัดสินใจ: ไม่ใช้ Domain Fixed Values — ใช้ Customized Table แทน ✅

**Fixed Values ของทั้ง 5 domain เว้นว่างไว้** ค่าทั้งหมดย้ายไปเก็บใน check table + ทำ value help
ผ่าน CDS view

เหตุผล: ต้องการเก็บ pattern ของ value-help-from-table ไว้เป็น reference implementation
สำหรับ project อื่นในอนาคต

**ผลที่ตามมาต่อ design เดิม**

| เรื่อง | เดิม | ใหม่ |
|-------|------|------|
| Fixed values | ใน domain | ใน check table |
| Phase 3 | Value Help Views (4 CDS view) | **Value Help Tables + Views** (ขยายขึ้น) |
| Sort order ของ status | ต้องฝังใน code (`10`,`20`,…) | มี column `sort_order` แยก → code ใช้ตัวย่อที่อ่านรู้เรื่องได้ |
| แก้ไขค่า | แก้ domain + activate | insert row ใน table |
| Column เพิ่มเติม | ไม่ได้ | ได้ — `criticality`, `is_active`, `valid_from` ฯลฯ |
| Validation | UI layer เท่านั้น | ผูก foreign key ที่ table ได้ + validate ใน behavior pool ได้ |

> 💡 **จุดที่ได้เปล่าจากการย้ายไป table**: ปัญหา "code ต้องเรียงลำดับได้" หายไป
> เดิมต้องเลือกระหว่าง `010/020/030` (sort ได้แต่อ่านไม่รู้เรื่อง) กับ `NEW/SPC/DEV`
> (อ่านรู้เรื่องแต่ sort ตามตัวอักษร) — พอมี column `sort_order` แยก เลือกได้ทั้งสองอย่าง

### 3.3 เนื้อหา Code List

✅ **ยืนยันครบทั้ง 5 กลุ่มแล้ว — ดูค่าจริงทั้งหมดที่ [`phase3_spec.md` §6](phase3_spec.md)**

| # | Code List | จำนวนค่า | หมายเหตุ |
|---|-----------|---------|---------|
| 1 | RICEFW Type | 6 | `RPT` `INTF` `CONV` `ENH` `FORM` `WF` |
| 2 | Delivery Type | 3 | `NEW` `LS` `REM` |
| 3 | Overall Status | 10 | `OPN`→`CLS` + `HLD` `CAN` · มี `criticality` |
| 4 | Role | 4 | `AB` `FN` `UI` `IC` |
| 5 | Object Type | 75 | อ้างอิง SAP Released ABAP Object Types · เปิดใช้ 30 ตัวผ่าน `is_active` |

> ค่าเหล่านี้เป็น **data ใน table** ไม่ใช่ metadata — เพิ่ม/แก้ทีหลังได้โดยไม่ต้องแตะ DDIC

### 3.4 นโยบายเรื่อง field ที่ยังไม่ระบุ type

Field ไหนที่ spec ให้มาแค่ **ชื่อ data element** โดยไม่ระบุ type ชัดเจน → ยึดตาม data element นั้นไปก่อน
ไม่ต้องเดา type เอง และไม่ต้องถามซ้ำ

| Field | Data element ที่ยึดไว้ | สถานะ |
|-------|----------------------|-------|
| `ricefw_type` | `YE_RICEFW_TYPE` | ✅ domain CHAR 6 — value help จาก table (Phase 3) |
| `overall_status` | `YE_OVERALL_STATUS` | ✅ domain CHAR 3 — value help จาก table (Phase 3) |
| `role` | `YE_ROLE` | ✅ domain CHAR 2 — value help จาก table (Phase 3) |
| `object_type` | `YE_OBJECT_TYPE` | ✅ domain CHAR 4 — value help จาก table (Phase 3) |
| `owner_id` | `vdm_userid` (SAP standard) | ตามที่ระบุ |
| `owner_name` | `vdm_userdescription` (SAP standard) | ตามที่ระบุ |

---

## 4. Package Structure

### ✅ ตัดสินใจ: Package เดียวแบบ flat — ไม่แบ่ง sub-package

Object ทั้งหมดอยู่ใน `YRICEFW` (encapsulated ✅) ไม่มี `_DB` / `_VH` / `_BO` / `_UI`

**เหตุผล**
- ประโยชน์หลักของการแบ่ง sub-package คือ **transport granularity** — แต่ app นี้อยู่บน `ZLOCAL`
  ไม่มี transport เลย ประโยชน์ข้อนี้จึงเป็นศูนย์
- ADT Project Explorer จัดกลุ่มตาม object type ให้อยู่แล้ว (Dictionary › Domains, Data Definitions,
  Behavior Definitions, …) การหา object ไม่ได้ยากขึ้น
- ตัดปัญหา package encapsulation ระหว่าง sibling package ทิ้งไปทั้งหมด
- ~30 object ใน package เดียวยังจัดการได้สบาย

ถ้าวันหนึ่งย้ายไปทำเป็นของจริงที่ต้อง transport ค่อยแตก sub-package แล้วย้าย object ทีหลังได้
(ADT: right-click object › Move)

### Object Inventory

| กลุ่ม | Object |
|-------|--------|
| **Domains** (9) ✅ | `YD_RICEFW_ID` `YD_RICEFW_TYPE` `YD_DELIVERY_TYPE` `YD_OVERALL_STATUS` `YD_ROLE` `YD_OBJECT_TYPE` `YD_TRANSPORT_TYPE` `YD_TRANSPORT_ID` `YD_TRANSPORT_STATUS` |
| **Data Elements** (9) ✅ | `YE_*` ตัวเดียวกับ domain ทุกตัว |
| **Tables — BO** (4) ✅ | `YRICEFW_HDR` `YRICEFW_OWNER` `YRICEFW_OBJ` `YRICEFW_TRSP` |
| **Tables — Draft** (4) ⏳ | `YRICEFW_HDR_D` `YRICEFW_OWNR_D` `YRICEFW_OBJ_D` `YRICEFW_TRSP_D` — generate ตอน Phase 5 |
| **Tables — Value Help** (14) ✅ | 7 code lists × (check + text) — ดู `phase3_spec.md` §3–4 |
| **Class — Generator** (1) ✅ | `YCL_RICEFW_VH_GEN` — โหลดค่า value help 318 records |
| **CDS — Value Help** (7) ✅ | `YI_RICEFW_TYPE_VH` `YI_RICEFW_DTYP_VH` `YI_RICEFW_STAT_VH` `YI_RICEFW_ROLE_VH` `YI_RICEFW_OTYP_VH` `YI_RICEFW_TTYP_VH` `YI_RICEFW_TRST_VH` |
| **CDS — BO** (4) ⏳ | `YR_RICEFW` `YI_RICEFW_OWNER` `YI_RICEFW_OBJECT` `YI_RICEFW_TRANSPORT` |
| **CDS — Projection** (4) ⏳ | `YC_RICEFW` `YC_RICEFW_OWNER` `YC_RICEFW_OBJECT` `YC_RICEFW_TRANSPORT` |
| **Behavior** (2) ⏳ | `YR_RICEFW` (bdef) `YC_RICEFW` (bdef projection) |
| **Class — Behavior Pool** (1) ⏳ | `YBP_RICEFW` |
| **Metadata Ext** (4) ⏳ | `YC_RICEFW` `YC_RICEFW_OWNER` `YC_RICEFW_OBJECT` `YC_RICEFW_TRANSPORT` |
| **Service** (2) ⏳ | `YUI_RICEFW` (srvd) `YUI_RICEFW_O4` (srvb) |

**รวม Phase 1–3: 44 objects** — 9 domains + 9 data elements + 4 tables + 14 value help tables + 1 generator class + 7 CDS views

### 4.2 GitHub / abapGit Mapping

abapGit ผูกที่ **package แม่ `YDMO_THIANTHAI`** ไม่ใช่ที่ `YRICEFW` — เพื่อให้ demo app ทุกตัว
อยู่ใต้ `/demo/` ใน repo เดียวกัน

| Setting | Value |
|---------|-------|
| Repo | `https://github.com/Thianthai/projects.git` (public) |
| Package ที่ผูก | `YDMO_THIANTHAI` |
| `STARTING_FOLDER` | `/demo/` |
| `FOLDER_LOGIC` | `FULL` |

```
ฝั่ง SAP                        ฝั่ง GitHub                  หมายเหตุ
─────────────────────          ──────────────────────      ─────────────────────────
YDMO_THIANTHAI       ────→     /demo/                      0 object (container)
├── YDMOFDP          ────→     /demo/ydmofdp/              Demo Form Data Provider (23)
├── YGRAPHIC         ────→     /demo/ygraphic/             Maintain Form Graphic (15)
├── YRICEFW          ────→     /demo/yricefw/              โปรเจกต์นี้ (5)
└── ZFIR001          ────→     /demo/zfir001/              Customer WHT Summary Report (54)
```

**หลักการ: 1 sub-package = 1 demo app**

> `ZFIR001` ยืนยันแล้วว่าเป็น demo app ที่ทำให้บริษัทตัวเองใช้ ไม่ใช่ code ของลูกค้า → publish ได้

> ⚠️ abapGit repo ตัวเดียวครอบทั้ง 4 app — pull ทีเดียวได้ทั้งหมด
> ส่วน commit แยกได้เพราะ abapGit ให้เลือก stage ทีละไฟล์ แต่แยก branch ราย app ไม่ได้

> **ทำไมใช้ `FULL` ไม่ใช่ `PREFIX`**
> `PREFIX` บังคับให้ชื่อ sub-package ขึ้นต้นด้วยชื่อ package แม่ (`YDMO_THIANTHAI_*`)
> ซึ่งจะได้ชื่อโฟลเดอร์ยาวและต้อง rename package เดิม
> `FULL` ใช้ชื่อ package เต็ม (ตัวพิมพ์เล็ก) เป็นชื่อโฟลเดอร์ → `YRICEFW` ได้ `/demo/yricefw/` พอดี
> โดยไม่ต้องแตะ package ที่มีอยู่เลย

> ⚠️ **ชื่อ package แม่ไม่มีผลกับชื่อโฟลเดอร์** — `STARTING_FOLDER` ตั้งเองได้อิสระ
> มีแต่ sub-package เท่านั้นที่ชื่อโฟลเดอร์มาจากชื่อ package

> ⚠️ **ทุกอย่างใต้ `YDMO_THIANTHAI` จะถูก push ขึ้น public repo** — package ที่ผูก abapGit
> คือขอบเขตของสิ่งที่จะถูกเผยแพร่ เอาเฉพาะของที่ publish ได้มาไว้ที่นี่

> ⚠️ **ไม่มีชั้น `src/`** — object ของ `YRICEFW` ลงที่ `/demo/yricefw/` ตรงๆ

### 4.3 Local Repo Structure

```
ricefw management/          →  GitHub: Thianthai/projects @ demo/yricefw/
├── CLAUDE.md                  (ignore ใน abapGit)
└── docs/                      (ignore ใน abapGit)
    ├── design.md
    └── phase*_spec.md
```

ไม่มีโฟลเดอร์ `src/` — ไฟล์ ABAP จะถูก abapGit เขียนลง `demo/yricefw/` บน GitHub โดยตรง
ฝั่ง local เก็บแค่เอกสาร

ไฟล์ที่ abapGit จะสร้างใน `demo/yricefw/` (ตัวอย่าง):
```
package.devc.xml               yd_ricefw_id.doma.xml
ye_ricefw_id.dtel.xml          yricefw_hdr.tabl.xml
yr_ricefw.ddls.asddls          yr_ricefw.bdef.asbdef
ybp_ricefw.clas.abap           yc_ricefw.ddlx.asddlxs
yui_ricefw.srvd.srvdsrv        yui_ricefw_o4.srvb.xml
```

เอกสาร (`README.md`, `CLAUDE.md`, `docs/`) อยู่โฟลเดอร์เดียวกับ ABAP object
ใส่ไว้ใน `<IGNORE>` ของ `.abapgit.xml` เพื่อไม่ให้ขึ้นมากวนใน diff view

> 💡 DOMA/DTEL ไม่มี source editor ใน ADT แต่ **abapGit serialize เป็น XML ให้เองได้**
> ดังนั้น domain/data element จะขึ้น GitHub ด้วย — `docs/phase*_spec.md` ยังมีประโยชน์
> ในฐานะเอกสารอธิบาย "ทำไมถึงตั้งค่าแบบนี้" ที่ XML ไม่ได้บอก

---

## 5. Implementation Plan

ทำทีละ Phase — จบ Phase หนึ่งแล้ว activate + ตรวจก่อนไป Phase ถัดไป

### Phase 0 — Project & Package Setup ✅ (บางส่วน)
- [x] สร้าง ABAP Cloud Project ใน ADT — system `L3S`
- [x] สร้าง package `YRICEFW`
  - Superpackage: `YDMO_THIANTHAI`
  - Package Type: `Development`
  - Default ABAP Language Version: **ABAP for Cloud Development** ✅
  - Software Component: `ZLOCAL` · Transport Layer: (ว่าง) → **local, transport ไม่ได้**
  - Package encapsulated: ✅
- [x] ~~สร้าง 4 sub-packages~~ — **ยกเลิก** ใช้ package เดียวแบบ flat (ดู §4)
- [x] ~~Transport Request~~ — ไม่มี เพราะ `ZLOCAL`

> ✅ **ยืนยันแล้ว: เป็น demo app — ใช้ `ZLOCAL` ถูกต้อง ไม่ต้อง transport**
> ผลที่ตามมาที่ต้องจำไว้: ไม่มี transport request, object ขึ้น QA/PRD ไม่ได้
> ถ้าวันหนึ่งอยากทำเป็นของจริง ต้องสร้าง package ใหม่ใต้ superpackage ที่อยู่ใน software component
> ที่ transport ได้ แล้วย้าย object ทั้งหมดไป (Software Component แก้ทีหลังไม่ได้)

### Phase 1 — Domains & Data Elements ✅
- [x] สร้าง 5 domains — **Fixed Values เว้นว่างทั้งหมด** (ย้ายไป check table, §3.2)
  - `YD_RICEFW_ID` CHAR 20 · `YD_RICEFW_TYPE` CHAR 6 · `YD_OVERALL_STATUS` CHAR 3
  - `YD_ROLE` CHAR 2 · `YD_OBJECT_TYPE` CHAR 4
  - Case-sensitive ไม่ติ๊กทุกตัว ✅
- [x] สร้าง 5 data elements + field label ครบ 4 ช่อง — ดู `phase1_spec.md` §2
  - `YE_RICEFW_ID` `YE_RICEFW_TYPE` `YE_OVERALL_STATUS` `YE_ROLE` `YE_OBJECT_TYPE`
  - Category: Domain ทุกตัว
- **Deliverable**: activate ผ่านทั้งหมด

### Phase 2 — Database Tables ✅
- [x] `YRICEFW_HDR` · `YRICEFW_OWNER` · `YRICEFW_OBJ` — activate ผ่าน 0 errors 0 warnings
- [x] ทุก table ต้องมี `@AbapCatalog.primaryKey.invertedIndividualIndex : true`
      ไม่งั้นติด warning *"Key must have the type Inverted Individual on the database"*
- [x] ~~Secondary index~~ — ยกเลิก 2 ตัว (HANA ไม่ต้องการ) · เลื่อน unique index บน `ricefw_id`
      ไป Phase 5 เพื่อทำพร้อม `validateRicefwId`
- **DDL เต็ม + เหตุผล**: ดู `phase2_spec.md`

### Phase 3 — Value Help Tables + Views ✅ จบแล้ว
- [x] เลือก pattern: **Option A** — check table + text table แยกต่อ code list
- [x] สร้างครบ 14 tables (7 code lists) — รวม transport ที่เพิ่มเข้ามาทีหลัง
- [x] `YCL_RICEFW_VH_GEN` — class generator โหลด 318 records (106 check + 212 text)
- [x] CDS view 7 ตัว: `YI_RICEFW_TYPE_VH` `YI_RICEFW_DTYP_VH` `YI_RICEFW_STAT_VH`
      `YI_RICEFW_ROLE_VH` `YI_RICEFW_OTYP_VH` `YI_RICEFW_TTYP_VH` `YI_RICEFW_TRST_VH`
  - `@ObjectModel.resultSet.sizeCategory: #XS` — **มีแค่ `#XS`/`#XXS` เท่านั้น** ไม่มี `#S`/`#M`/`#L`
  - `@Search.searchable` + `@Search.defaultSearchElement` บน description
  - `@Semantics.text: true` บน description
  - ~~`ORDER BY`~~ **ใช้ไม่ได้ใน View Entity** — เก็บ `SortOrder` ไว้ในผลลัพธ์แทน
    ควบคุมการเรียงที่ `@UI.presentationVariant` ตอน metadata extension (Phase 6/7)
- **รายละเอียดเต็ม + 2 บทเรียนที่เจอ**: ดู `phase3_spec.md` §9–10

### Phase 4 — CDS Data Model (Interface + Root)
- [ ] `YI_RICEFW_OWNER` — child view + `association to parent`
- [ ] `YI_RICEFW_OBJECT` — child view + `association to parent`
- [ ] `YI_RICEFW_TRANSPORT` — child view + `association to parent`
- [ ] `YR_RICEFW` — root view entity + `composition [0..*]` ทั้ง 3 child
- [ ] `YI_RICEFW_OWNER` — ประกาศ association `_User : [0..1] to I_User` ไว้ **แต่ยังไม่ expose field** (เผื่อ upgrade §2.3)
- [ ] `@ObjectModel.dataCategory`, `@AccessControl.authorizationCheck: #NOT_REQUIRED` (ชั่วคราว)
- **Deliverable**: preview root view ได้, expand ไป child ได้

### Phase 5 — Behavior Definition & Implementation
- [ ] `YR_RICEFW` bdef — `managed; strict(2);` + `with draft;`
- [ ] Generate draft tables ผ่าน ADT quick fix
- [ ] Field characteristics:
  - `readonly` — admin fields ทั้งหมด (`created_*`, `last_changed_*`, `local_last_changed_at`) + UUID ทุกตัว
  - `mandatory` — `ricefw_id`, `description`, `ricefw_type`
- [ ] `numbering : managed` สำหรับ UUID ทุก entity (early numbering)
- [ ] `etag master local_last_changed_at` ทุก entity + `total etag last_changed_at` ที่ root
- [ ] Behavior pool `YBP_RICEFW`
  - Determination `setInitialStatus` — default `overall_status = 10` ตอน create
  - Validation `validateRicefwId` — ห้ามว่าง + **ห้ามซ้ำกับ instance อื่น** (เพราะ user กรอกเอง)
  - Validation `validateDates` — `plan_finish >= plan_start`
  - Validation `validateProgress` — `progress` อยู่ในช่วง 0–100
  - Validation `validateOwner` — `owner_id` / `owner_name` ห้ามว่าง (ไม่เช็คกับ `I_User` — owner อาจเป็น external)
- **Deliverable**: EML test class ใน `ybp_ricefw.clas.testclasses.abap` ผ่าน

> ❌ **ไม่มี number range** — `ricefw_id` เป็น free text ที่ user กรอกเอง
> ความถูกต้องอยู่ที่ `validateRicefwId` + unique index แทน
>
> **จุดที่ต้องระวังใน `validateRicefwId`**: ต้องเช็คซ้ำทั้งกับ active data (`SELECT` จาก `YRICEFW_HDR`)
> และกับ instance อื่นใน request เดียวกัน (`READ ENTITIES` ทุก key ที่ถูกแตะ) ไม่งั้นถ้า user
> สร้าง 2 record ที่มี ID เดียวกันพร้อมกัน จะหลุดไปชนที่ DB index

### Phase 6 — Projection Views & Behavior Projection
- [ ] `YC_RICEFW`, `YC_RICEFW_OWNER`, `YC_RICEFW_OBJECT`, `YC_RICEFW_TRANSPORT`
- [ ] `@Search.searchable` + `@Consumption.valueHelpDefinition` ผูก value help views
- [ ] `YC_RICEFW` bdef — `projection; strict(2); use draft;`
- **Deliverable**: projection activate ผ่าน

### Phase 7 — Metadata Extensions (UI)
- [ ] `YC_RICEFW` MDE
  - List Report: `@UI.lineItem`, `@UI.selectionField`, `@UI.headerInfo`
  - Object Page: `@UI.facet` (General Info / Schedule / Owners / Objects)
  - `@UI.criticality` ผูกกับ `overall_status`
- [ ] `YC_RICEFW_OWNER` MDE — table facet + progress indicator
- [ ] `YC_RICEFW_OBJECT` MDE — table facet
- [ ] `YC_RICEFW_TRANSPORT` MDE — table facet + criticality บน `transport_status`
- **Deliverable**: annotation ครบ, ไม่มี warning

### Phase 8 — Service Exposure
- [ ] Service Definition `YUI_RICEFW` — expose 4 projection views + value helps
- [ ] Service Binding `YUI_RICEFW_O4` (OData V4 — UI)
- [ ] Publish local service endpoint
- [ ] Preview ใน Fiori Elements Preview
- **Deliverable**: สร้าง/แก้/ลบ RICEFW ผ่าน UI ได้จริง

### Phase 9 — Security & Finishing
- [ ] เปลี่ยน `@AccessControl.authorizationCheck` เป็น `#CHECK` + สร้าง DCL
- [ ] Authorization object + `authorization master` ใน bdef
- [ ] IAM App (`YUI_RICEFW_O4`) → Business Catalog → Business Role
- [ ] ABAP Unit tests ครอบ validation/determination
- [ ] Test data generator class `YCL_RICEFW_DATA_GEN`

---

## 6. Decisions Log

### ✅ ยืนยันแล้ว (2026-08-06)

| # | หัวข้อ | ข้อสรุป |
|---|--------|---------|
| 1 | Domain fixed values | ❌ **ไม่ใช้** — เว้นว่างทุก domain แล้วเก็บค่าใน customized check table แทน (§3.2, §7) เพื่อเก็บ pattern ไว้เป็น reference สำหรับ project อื่น |
| 2 | `owner_name` | เก็บใน table, **user กรอกเอง** (ไม่ auto-fill) + ประกาศ association `I_User` ทิ้งไว้เผื่อ upgrade |
| 3 | `ricefw_id` | **free text CHAR 20** — ไม่มี number range, ใช้ validation + unique index แทน |
| 4 | Draft | **มี draft** — ต้องสร้าง draft table ครบทั้ง 3 entity |
| 5 | Field ที่ระบุแค่ data element | ยึดตาม data element นั้นไปก่อน ไม่ต้องเดา type — รอ spec เพิ่มตอนถึง phase นั้น |
| 6 | Value help | **ทุก code list มาจาก customized table** (`ricefw_type`, `overall_status`, `role`, `object_type`) — ทำเป็น reference implementation |
| 7 | Scope ของ app | **Demo app** — package `YRICEFW` อยู่บน software component `ZLOCAL`, ไม่ transport |
| 8 | Package structure | **Flat — package เดียว** `YRICEFW` (encapsulated ✅) ไม่แบ่ง sub-package (§4) |
| 9 | Domain case-sensitive | ทุก domain ไม่ติ๊ก Case-sensitive (บังคับ uppercase) — สำคัญกับ `YD_RICEFW_ID` |
| 10 | ชื่อ object | ยึด **RICEFW** ทุกที่ (`YD_WRICEF_*` รอบแรกเป็นการพิมพ์ผิด แก้แล้ว) |
| 11 | Domain lengths | `_ID` 20 · `_TYPE` 6 · `_STATUS` 3 · `_ROLE` 2 · `_OBJECT_TYPE` 4 |

### ⏳ ยังไม่สรุป

| # | หัวข้อ | สถานะ |
|---|--------|-------|
| A | **Pattern ของ value help table** | 3 ทางเลือกใน §7 — รอเลือกก่อนเริ่ม Phase 3 |
| B | เนื้อหา code list (§3.3) | ร่างไว้แล้วให้พอดีกับ length ใหม่ — รอ user ยืนยัน/ปรับ |
| C | API service `YAPI_RICEFW` | ยังไม่ทำใน scope นี้ — เพิ่มทีหลังได้บน CDS layer เดิม |
| D | Authorization concept (DCL, auth object) | ออกแบบตอน Phase 9 |

---

## 7. Value Help Table — 3 ทางเลือก (รอตัดสินใจ)

ทั้ง 3 แบบใช้ CDS view ชื่อเดียวกัน (`YI_*_VH`) และ `@Consumption.valueHelpDefinition`
เหมือนกันหมด — ต่างกันแค่ที่โครงสร้าง table ข้างล่าง

### Option A — Check table + Text table แยกต่อ list (8 tables)

Pattern มาตรฐานที่ SAP ใช้เอง (T-table + T-table text)

```
YRICEFW_TYPE    : client, ricefw_type(key), sort_order, is_active
YRICEFW_TYPET   : client, spras(key), ricefw_type(key), description
YRICEFW_STAT    : client, overall_status(key), sort_order, criticality, is_active
YRICEFW_STATT   : client, spras(key), overall_status(key), description
YRICEFW_ROLE    : client, role(key), sort_order, is_active
YRICEFW_ROLET   : client, spras(key), role(key), description
YRICEFW_OTYP    : client, object_type(key), sort_order, is_active
YRICEFW_OTYPT   : client, spras(key), object_type(key), description
```

| ข้อดี | ข้อเสีย |
|-------|---------|
| Text แปลหลายภาษาได้ (ไทย/อังกฤษ) | 8 tables — สร้างเยอะ |
| ผูก Value Table ที่ domain ได้ตรงๆ → foreign key check ระดับ DDIC | CDS view ต้อง join 2 table |
| เป็นตัวอย่างที่ตรงกับ SAP standard มากที่สุด | |
| Field มี type ตรงกับ data element จริง (type-safe) | |

### Option B — Table เดียวต่อ list, description อยู่ในตัว (4 tables)

```
YRICEFW_TYPE : client, ricefw_type(key), description, sort_order, is_active
YRICEFW_STAT : client, overall_status(key), description, sort_order, criticality, is_active
YRICEFW_ROLE : client, role(key), description, sort_order, is_active
YRICEFW_OTYP : client, object_type(key), description, sort_order, is_active
```

| ข้อดี | ข้อเสีย |
|-------|---------|
| แค่ 4 tables, CDS view ไม่ต้อง join | ภาษาเดียว — แปลไม่ได้ |
| ยัง type-safe (key เป็น data element จริง) | |
| ผูก Value Table ที่ domain ได้ | |

### Option C — Generic code table ตัวเดียว (2 tables)

```
YRICEFW_CODE  : client, code_list(key,CHAR20), code(key,CHAR20), sort_order, criticality, is_active
YRICEFW_CODET : client, spras(key), code_list(key), code(key), description
```
CDS view แต่ละตัว filter ด้วย `code_list = 'RICEFW_TYPE'` แล้ว cast `code` เป็น type ที่ต้องการ

| ข้อดี | ข้อเสีย |
|-------|---------|
| แค่ 2 tables — เพิ่ม code list ใหม่ไม่ต้องสร้าง DDIC object | `code` เป็น CHAR 20 generic — ต้อง `cast()` ใน CDS ทุก view |
| Maintenance UI ตัวเดียวคุมทุก list | ผูก Value Table ที่ domain ไม่ได้ → ไม่มี FK check ระดับ DDIC |
| | ไม่ตรงกับ pattern ที่เจอใน SAP standard |

### 💡 คำแนะนำ

**เลือก Option A** ถ้าเป้าหมายคือเก็บไว้เป็น reference implementation ตามที่ตั้งใจ —
เป็น pattern ที่ตรงกับ SAP standard ที่สุด และครอบคลุมทุกเรื่องที่จะเจอใน project จริง
(text table หลายภาษา, foreign key check, sort order, active flag)

**เลือก Option B** ถ้าอยากได้เร็วกว่าและ app นี้ไม่ต้องรองรับหลายภาษา — ตัดงานลงครึ่งหนึ่ง
โดยยังคงส่วนที่เป็นสาระของ pattern ไว้ครบ

**Option C** เหมาะกับตอนที่มี code list เยอะมาก (10+) — สำหรับ 4 lists ยังไม่คุ้มกับที่ต้องเสีย type safety ไป
