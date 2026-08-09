# Phase 1 — Domains & Data Elements (Spec)

Package: `YRICEFW` (flat) · ABAP Language Version: ABAP for Cloud Development
สร้างผ่าน form editor ใน ADT (DOMA/DTEL ไม่มี source editor)

---

## 1. Domains — ✅ สร้างเสร็จแล้ว

> `YD_DELIVERY_TYPE` และ `YD_TRANSPORT_*` ถูกเพิ่มทีหลังตอน Phase 3 (ดู `phase3_spec.md` §7, §8)
> รวมไว้ที่นี่เพื่อให้เอกสารนี้เป็นรายการ DDIC element ที่ครบถ้วนในที่เดียว

| Domain | Description | Data Type | Length | Output Len | Case-sensitive | Fixed Values |
|--------|-------------|-----------|--------|-----------|----------------|--------------|
| `YD_RICEFW_ID` | RICEFW ID | CHAR | 20 | 20 | ❌ | — |
| `YD_RICEFW_TYPE` | RICEFW Type | CHAR | 6 | 6 | ❌ | — |
| `YD_OVERALL_STATUS` | Overall Status | CHAR | 3 | 3 | ❌ | — |
| `YD_ROLE` | Role | CHAR | 2 | 2 | ❌ | — |
| `YD_OBJECT_TYPE` | Object Type | CHAR | 4 | 4 | ❌ | — |
| `YD_DELIVERY_TYPE` | Delivery Type | CHAR | 6 | 6 | ❌ | — |
| `YD_TRANSPORT_TYPE` | Transport Type | CHAR | 3 | 3 | ❌ | — |
| `YD_TRANSPORT_ID` | Transport ID | CHAR | 40 | 40 | ❌ | — |
| `YD_TRANSPORT_STATUS` | Transport Status | CHAR | 3 | 3 | ❌ | — |

### ✅ Fixed Values เว้นว่างทั้งหมด — ถูกต้องแล้ว

ค่า code list ทั้งหมดย้ายไปเก็บใน **customized check table** (`phase3_spec.md`)
เพื่อเก็บ pattern ของ value-help-from-table ไว้เป็น reference implementation

### ✅ Value Table — ใส่ครบแล้วตอน Phase 3

ช่อง **Value Table** ล่างสุดของ domain editor ผูกกับ check table เพื่อเปิด foreign key check ระดับ DDIC

| Domain | Value Table |
|--------|-------------|
| `YD_RICEFW_TYPE` | `YRICEFW_TYPE_VH` |
| `YD_DELIVERY_TYPE` | `YRICEFW_DTYP_VH` |
| `YD_OVERALL_STATUS` | `YRICEFW_STAT_VH` |
| `YD_ROLE` | `YRICEFW_ROLE_VH` |
| `YD_OBJECT_TYPE` | `YRICEFW_OTYP_VH` |
| `YD_TRANSPORT_TYPE` | `YRICEFW_TTYP_VH` |
| `YD_TRANSPORT_STATUS` | `YRICEFW_TRST_VH` |

`YD_RICEFW_ID` และ `YD_TRANSPORT_ID` ไม่มี Value Table — เป็น free text ไม่ใช่ code list

### หมายเหตุ Case-sensitive

ADT ใช้คำว่า **"Case-sensitive"** ซึ่งกลับด้านกับ **"Lower Case"** ใน SE11 เดิม
- ไม่ติ๊ก = บังคับ uppercase ✅ (ที่ต้องการ)
- ติ๊ก = เก็บตัวพิมพ์เล็กได้

สำคัญกับ `YD_RICEFW_ID` เป็นพิเศษ เพราะเป็น free text ที่ user กรอกเอง ถ้าพิมพ์ตัวเล็กได้
`rpt-001` กับ `RPT-001` จะเป็นคนละ ID unique index ไม่จับ

---

## 2. Data Elements — ✅ สร้างครบแล้ว

Category: **Domain** ทุกตัว (ไม่ใช่ Predefined Type)

| Data Element | Type Name (Domain) | Type | Short (10) | Medium (20) | Long (40) | Heading (55) |
|--------------|--------------------|------|-----------|-------------|-----------|--------------|
| `YE_RICEFW_ID` | `YD_RICEFW_ID` | CHAR 20 | RICEFW ID | RICEFW ID | RICEFW ID | RICEFW ID |
| `YE_RICEFW_TYPE` | `YD_RICEFW_TYPE` | CHAR 6 | RICEFW Typ | RICEFW Type | RICEFW Type | RICEFW Type |
| `YE_OVERALL_STATUS` | `YD_OVERALL_STATUS` | CHAR 3 | Overall St | Overall Status | Overall Status | Overall Status |
| `YE_ROLE` | `YD_ROLE` | CHAR 2 | Role | Role | Role | Role |
| `YE_OBJECT_TYPE` | `YD_OBJECT_TYPE` | CHAR 4 | Object Typ | Object Type | Object Type | Object Type |
| `YE_DELIVERY_TYPE` | `YD_DELIVERY_TYPE` | CHAR 6 | Deliv Type | Delivery Type | Delivery Type | Delivery Type |
| `YE_TRANSPORT_TYPE` | `YD_TRANSPORT_TYPE` | CHAR 3 | Transp Typ | Transport Type | Transport Type | Transport Type |
| `YE_TRANSPORT_ID` | `YD_TRANSPORT_ID` | CHAR 40 | Transp ID | Transport ID | Transport Request / Software Collection | Transport Request / Software Collection |
| `YE_TRANSPORT_STATUS` | `YD_TRANSPORT_STATUS` | CHAR 3 | Transp St | Transport Status | Transport Status | Transport Status |

> Field label คือข้อความที่ขึ้นบน UI ถ้าไม่ override ด้วย `@EndUserText.label` ใน CDS
> Short จำกัด 10 ตัวอักษรจึงต้องตัดคำ — เลือกคำที่ตัดแล้วยังอ่านออก
> (`Deliv Type` ดีกว่า `Delive Typ` เพราะเก็บ `Type` ไว้ครบและ `Deliv` เดาออกว่า Delivery)

### 📌 บันทึกไว้: RICEFW vs WRICEF

ระหว่างทางมีการสับสนระหว่าง 2 คำนี้ — **ทั้งคู่ถูกต้องและ SAP ใช้ทั้งสองแบบ**
(SAP Community ใช้ `RICEFW`, SAP Help Portal และ SAP PRESS ใช้ `WRICEF`)
ความหมายเหมือนกัน: Reports, Interfaces, Conversions, Enhancements, Forms, Workflows

**โปรเจกต์นี้ยึด `RICEFW` ทุกที่** ทั้งชื่อ object, field label และชื่อ GitHub repo

---

## 3. Field ที่ไม่ต้องสร้าง Data Element

ใช้ built-in type / SAP standard data element ตรงๆ ใน table

| Field | Type | หมายเหตุ |
|-------|------|---------|
| `ricefw_uuid` / `owner_uuid` / `object_uuid` | `sysuuid_x16` | SAP standard |
| `description` | `abap.char(80)` | built-in |
| `object_name` | `abap.char(40)` | built-in |
| `plan_start` / `plan_finish` | `abap.datn` | built-in |
| `remark` | `abap.string(0)` | built-in |
| `progress` | `abap.int1` | built-in — validate 0–100 ใน Phase 5 |
| `owner_id` | `vdm_userid` | SAP standard |
| `owner_name` | `vdm_userdescription` | SAP standard |
| admin fields | `abp_*` | SAP standard (RAP) |

---

## 4. Checklist

- [x] `YD_RICEFW_ID`
- [x] `YD_RICEFW_TYPE`
- [x] `YD_OVERALL_STATUS`
- [x] `YD_ROLE`
- [x] `YD_OBJECT_TYPE`
- [x] `YE_RICEFW_ID`
- [x] `YE_RICEFW_TYPE`
- [x] `YE_OVERALL_STATUS`
- [x] `YE_ROLE`
- [x] `YE_OBJECT_TYPE`
- [x] `YD_DELIVERY_TYPE` · `YE_DELIVERY_TYPE` *(เพิ่มตอน Phase 3)*
- [x] `YD_TRANSPORT_TYPE` · `YD_TRANSPORT_ID` · `YD_TRANSPORT_STATUS` *(เพิ่มตอน Phase 3 — transport)*
- [x] `YE_TRANSPORT_TYPE` · `YE_TRANSPORT_ID` · `YE_TRANSPORT_STATUS`
- [x] Activate ทั้งหมด ไม่มี error/warning
- [x] *(Phase 3)* ใส่ Value Table ที่ domain 5 ตัวแรกแล้ว
- [x] *(Phase 3)* ใส่ Value Table ที่ `YD_TRANSPORT_TYPE` · `YD_TRANSPORT_STATUS`
