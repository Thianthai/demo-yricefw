# Phase 3 — Value Help Tables + Views (Spec)

Package: `YRICEFW` · **Option A** — check table + text table แยกต่อ code list (**14 tables**)

---

## 1. ภาพรวม

| # | Code List | Data Element | Check Table | Text Table | สถานะ |
|---|-----------|--------------|-------------|------------|-------|
| 1 | RICEFW Type | `YE_RICEFW_TYPE` | `YRICEFW_TYPE_VH` | `YRICEFW_TYPE_VHT` | ✅ สร้างแล้ว |
| 2 | Overall Status | `YE_OVERALL_STATUS` | `YRICEFW_STAT_VH` | `YRICEFW_STAT_VHT` | ✅ สร้างแล้ว |
| 3 | Role | `YE_ROLE` | `YRICEFW_ROLE_VH` | `YRICEFW_ROLE_VHT` | ✅ สร้างแล้ว |
| 4 | Object Type | `YE_OBJECT_TYPE` | `YRICEFW_OTYP_VH` | `YRICEFW_OTYP_VHT` | ✅ สร้างแล้ว |
| 5 | **Delivery Type** | `YE_DELIVERY_TYPE` | `YRICEFW_DTYP_VH` | `YRICEFW_DTYP_VHT` | ✅ สร้างแล้ว |
| 6 | **Transport Type** | `YE_TRANSPORT_TYPE` | `YRICEFW_TTYP_VH` | `YRICEFW_TTYP_VHT` | ✅ สร้างแล้ว |
| 7 | **Transport Status** | `YE_TRANSPORT_STATUS` | `YRICEFW_TRST_VH` | `YRICEFW_TRST_VHT` | ✅ สร้างแล้ว |

รวม **14 tables** — เดิมวางไว้ 8 · เพิ่มกลุ่ม 5 ตอนแยก `delivery_type` (§7) · เพิ่มกลุ่ม 6–7 ตอนเพิ่ม transport table (§8)

**Naming**: `_VH` = value help (check table) · `_VHT` = value help text
วาง `T` ไว้ท้ายเพื่อให้ check กับ text ของ list เดียวกันเรียงติดกัน — และแยกออกจาก
table ธุรกรรม (`YRICEFW_HDR` / `_OWNER` / `_OBJ`) ได้ทันทีจากชื่อ

## 2. ต่างจาก Transaction Table ตรงไหน

| | Transaction table | Value help table |
|---|---|---|
| `deliveryClass` | `#A` application data | **`#C`** customizing — transport ข้ามระบบได้ |
| `dataMaintenance` | `#RESTRICTED` | **`#ALLOWED`** — maintain ค่าผ่าน tool ได้ |
| Admin fields | มีครบ (`created_by` ฯลฯ) | ไม่มี — เป็น config ไม่ใช่ transaction |
| `invertedIndividualIndex` | ✅ ต้องมี | ✅ **check table ต้องมี** · ❌ text table ไม่ต้อง |

> `deliveryClass #C` สำคัญ — ทำให้ค่า code list เดินทางไปพร้อม transport ตอน deploy
> ถ้าใช้ `#A` ค่าจะไม่ตามไป ต้องไปนั่งใส่ใหม่ทุกระบบ

### 2.1 กฎของ `invertedIndividualIndex` — ขึ้นกับ **จำนวน key field**

พิสูจน์จาก 18 table ที่สร้างมาแล้ว แบ่งขาด 11:7

| Key fields | ตัวอย่าง | Warning |
|-----------|---------|---------|
| **2 คอลัมน์** | `client` + `ricefw_uuid` (RAW 16)<br>`client` + `role` (CHAR 2) | ⚠️ **ต้องใส่ annotation** |
| **3 คอลัมน์** | `client` + `spras` + `role` | ✅ ไม่ต้องใส่ |

key type ที่ติด warning มีตั้งแต่ `RAW 16` ถึง `CHAR 2` — **ชนิดข้อมูลไม่เกี่ยว จำนวนคอลัมน์เท่านั้น**

**เหตุผล**: index แบบ Inverted Value (default) สร้างคอลัมน์ภายในที่เก็บ key ทุกคอลัมน์ต่อกัน
ถ้า key มีแค่ `client` (แทบเป็นค่าเดียวทั้ง table) + คอลัมน์จริง 1 ตัว คอลัมน์ที่ต่อกันนั้น
แทบไม่ต่างจากคอลัมน์เดียว → เปลืองเปล่า HANA จึงแนะนำให้ index แยกทีละคอลัมน์
พอมี 3 คอลัมน์ขึ้นไป การ intersect index หลายตัวเริ่มแพง คอลัมน์ที่ต่อกันจึงเริ่มคุ้ม

> สรุปจากหลักฐานที่สังเกตได้ ไม่ใช่จากเอกสาร SAP (ค้นแล้วไม่เจอ) แต่ sample ครอบคลุม
> key type หลากหลายพอที่จะตัดตัวแปรอื่นออกได้

---

## 3. DDL — Check Tables

### 3.1 `YRICEFW_TYPE_VH`

```abap
@EndUserText.label : 'RICEFW Type – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_type_vh {
  key client      : abap.clnt not null;
  key ricefw_type : ye_ricefw_type not null;
  sort_order      : abap.int1;
  is_active       : abap_boolean;
}
```

### 3.2 `YRICEFW_STAT_VH`

```abap
@EndUserText.label : 'Overall Status – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_stat_vh {
  key client         : abap.clnt not null;
  key overall_status : ye_overall_status not null;
  sort_order         : abap.int1;
  criticality        : abap.int1;
  is_active          : abap_boolean;
}
```

> `criticality` มีเฉพาะ table นี้ — ใช้ระบายสี status บน Fiori ใน Phase 7
> (`0` Neutral · `1` Negative · `2` Warning · `3` Positive)

### 3.3 `YRICEFW_ROLE_VH`

```abap
@EndUserText.label : 'Role – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_role_vh {
  key client : abap.clnt not null;
  key role   : ye_role not null;
  sort_order : abap.int1;
  is_active  : abap_boolean;
}
```

### 3.4 `YRICEFW_OTYP_VH`

```abap
@EndUserText.label : 'Object Type – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_otyp_vh {
  key client      : abap.clnt not null;
  key object_type : ye_object_type not null;
  sort_order      : abap.int1;
  is_active       : abap_boolean;
}
```

### 3.5 `YRICEFW_DTYP_VH`

```abap
@EndUserText.label : 'Delivery Type – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_dtyp_vh {
  key client        : abap.clnt not null;
  key delivery_type : ye_delivery_type not null;
  sort_order        : abap.int1;
  is_active         : abap_boolean;
}
```

### 3.6 `YRICEFW_TTYP_VH`

```abap
@EndUserText.label : 'Transport Type – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_ttyp_vh {
  key client         : abap.clnt not null;
  key transport_type : ye_transport_type not null;
  sort_order         : abap.int1;
  is_active          : abap_boolean;
}
```

### 3.7 `YRICEFW_TRST_VH`

```abap
@EndUserText.label : 'Transport Status – Value Help'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
@AbapCatalog.primaryKey.invertedIndividualIndex : true
define table yricefw_trst_vh {
  key client           : abap.clnt not null;
  key transport_status : ye_transport_status not null;
  sort_order           : abap.int1;
  criticality          : abap.int1;
  is_active            : abap_boolean;
}
```

---

## 4. DDL — Text Tables

โครงเหมือนกันทุกตัว: `client` + `spras` + code เป็น key แล้วมี `description`

### 4.1 `YRICEFW_TYPE_VHT`

```abap
@EndUserText.label : 'RICEFW Type – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_type_vht {
  key client      : abap.clnt not null;
  key spras       : abap.lang not null;
  key ricefw_type : ye_ricefw_type not null;
  description     : abap.char(60);
}
```

### 4.2 `YRICEFW_STAT_VHT`

```abap
@EndUserText.label : 'Overall Status – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_stat_vht {
  key client         : abap.clnt not null;
  key spras          : abap.lang not null;
  key overall_status : ye_overall_status not null;
  description        : abap.char(60);
}
```

### 4.3 `YRICEFW_ROLE_VHT`

```abap
@EndUserText.label : 'Role – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_role_vht {
  key client : abap.clnt not null;
  key spras  : abap.lang not null;
  key role   : ye_role not null;
  description : abap.char(60);
}
```

### 4.4 `YRICEFW_OTYP_VHT`

```abap
@EndUserText.label : 'Object Type – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_otyp_vht {
  key client      : abap.clnt not null;
  key spras       : abap.lang not null;
  key object_type : ye_object_type not null;
  description     : abap.char(60);
}
```

### 4.5 `YRICEFW_DTYP_VHT`

```abap
@EndUserText.label : 'Delivery Type – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_dtyp_vht {
  key client        : abap.clnt not null;
  key spras         : abap.lang not null;
  key delivery_type : ye_delivery_type not null;
  description       : abap.char(60);
}
```

### 4.6 `YRICEFW_TTYP_VHT`

```abap
@EndUserText.label : 'Transport Type – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_ttyp_vht {
  key client         : abap.clnt not null;
  key spras          : abap.lang not null;
  key transport_type : ye_transport_type not null;
  description        : abap.char(60);
}
```

### 4.7 `YRICEFW_TRST_VHT`

```abap
@EndUserText.label : 'Transport Status – Value Help Text'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table yricefw_trst_vht {
  key client           : abap.clnt not null;
  key spras            : abap.lang not null;
  key transport_status : ye_transport_status not null;
  description          : abap.char(60);
}
```

---

## 5. ขั้นตอนที่เหลือหลังสร้าง table

- [x] **ใส่ Value Table ที่ domain ครบทั้ง 5** — activate ผ่านทั้งหมด
      | Domain | Value Table |
      |---|---|
      | `YD_RICEFW_TYPE` | `YRICEFW_TYPE_VH` |
      | `YD_DELIVERY_TYPE` | `YRICEFW_DTYP_VH` |
      | `YD_OVERALL_STATUS` | `YRICEFW_STAT_VH` |
      | `YD_ROLE` | `YRICEFW_ROLE_VH` |
      | `YD_OBJECT_TYPE` | `YRICEFW_OTYP_VH` |
      | `YD_TRANSPORT_TYPE` | `YRICEFW_TTYP_VH` |
      | `YD_TRANSPORT_STATUS` | `YRICEFW_TRST_VH` |
- [ ] **Load ค่าเริ่มต้น** — ค่าตาม §6 ผ่าน class generator `YCL_RICEFW_VH_GEN`
- [ ] **สร้าง CDS view** 7 ตัว — `YI_RICEFW_TYPE_VH` ฯลฯ join check + text table

## 6. ค่าที่จะ Load — ยืนยันครบทั้ง 7 กลุ่มแล้ว ✅

**ภาษา**: text table มี 2 record ต่อ 1 code (`EN` + `TH`) ใช้ description เดียวกันทั้งคู่
ไว้แปลไทยจริงทีหลังก็ update record `TH` อย่างเดียว

### 6.1 RICEFW Type — `YRICEFW_TYPE_VH`

| Code | Description | sort | active |
|------|-------------|------|--------|
| `RPT` | Report | 10 | X |
| `INTF` | Interface | 20 | X |
| `CONV` | Conversion | 30 | X |
| `ENH` | Enhancement | 40 | X |
| `FORM` | Form | 50 | X |
| `WF` | Workflow | 60 | X |

เรียงตามลำดับตัวอักษรใน RICEFW เพื่อให้คนที่คุ้นกับคำนี้อ่านแล้วไม่สะดุด

### 6.2 Delivery Type — `YRICEFW_DTYP_VH` ✨ ใหม่

| Code | Description | sort | active |
|------|-------------|------|--------|
| `NEW` | New Development | 10 | X |
| `LS` | Lift and Shift | 20 | X |
| `REM` | Remediate | 30 | X |

### 6.3 Overall Status — `YRICEFW_STAT_VH`

| Code | Description | sort | criticality | active |
|------|-------------|------|-------------|--------|
| `OPN` | Not Assigned | 10 | 2 Warning | X |
| `PND` | Pending | 20 | 0 Neutral | X |
| `DEV` | In Development | 30 | 0 Neutral | X |
| `UT` | Unit Testing | 40 | 0 Neutral | X |
| `FAT` | Functional Testing | 50 | 0 Neutral | X |
| `SIT` | Integration Testing | 60 | 0 Neutral | X |
| `UAT` | User Testing | 70 | 0 Neutral | X |
| `CLS` | Done | 80 | 3 Positive | X |
| `HLD` | On Hold | 90 | 2 Warning | X |
| `CAN` | Cancelled | 99 | 1 Negative | X |

**หลักการของ key**: เปิดด้วย `OPN` (Open) ปิดด้วย `CLS` (Close) — จงใจให้ code สื่อจุดเริ่ม-จบ
แม้ description จะไม่ตรงตัว เพราะ description ต้องสื่อกับคนกรอกข้อมูลให้ชัดที่สุด

**หลักการของ criticality**: สีสื่อ *"ต้องจัดการไหม"* ไม่ใช่ *"อยู่ขั้นไหน"*
- 🟡 `OPN` ยังไม่มีคนรับผิดชอบ · `HLD` พักไว้ → ต้องจัดการ
- ⬜ ระหว่างทาง → เดินตามปกติ
- 🟢 `CLS` จบแล้ว · 🔴 `CAN` จบแบบไม่ได้ส่งมอบ (แยกจาก `CLS` ชัดเจนบน list report)

`HLD`/`CAN` วางไว้ท้ายเพราะออกจากเส้นทางปกติได้ทุกจุด ไม่ได้อยู่ขั้นใดขั้นหนึ่ง

### 6.4 Role — `YRICEFW_ROLE_VH`

| Code | Description | sort | active |
|------|-------------|------|--------|
| `AB` | ABAP Developer | 10 | X |
| `FN` | Functional Consultant | 20 | X |
| `UI` | Front-end Developer | 30 | X |
| `IC` | Integration Consultant | 40 | X |

**ไม่มีทีม tester แยก** — `AB` รับผิดชอบช่วง `DEV`/`UT` · `FN` รับผิดชอบช่วง `FAT`/`SIT`/`UAT`

### 6.5 Object Type — `YRICEFW_OTYP_VH`

**ที่มา**: [Released ABAP Object Types — SAP Help Portal](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/b31aa03640b940d5981ce2af1cd0a019.html)
(S/4HANA Cloud Public Edition › Developer Extensibility › Working with abapGit · เวอร์ชัน 2608)

**75 object types** — code ยาว 4 ตัวอักษรทุกตัวพอดี `YD_OBJECT_TYPE` CHAR 4 ✅
`sort_order` = 10, 20, 30… ตามลำดับตัวอักษร

**กลยุทธ์ `is_active`**: โหลดครบทั้ง 75 ตามมาตรฐาน SAP แต่**เปิดใช้แค่ 30 ตัว**
ที่เกี่ยวข้องกับงาน RICEFW จริง — CDS view จะกรอง `is_active = 'X'` ก่อนส่งเข้า value help
ได้ทั้งความครบถ้วนของข้อมูลอ้างอิงและ dropdown ที่ใช้งานได้จริง
เปิดตัวไหนเพิ่มทีหลังก็แค่ update 1 ฟิลด์ ไม่ต้องแก้โค้ด

**30 ตัวที่เปิดใช้ (`is_active = X`)**
```
BDEF  CLAS  DCLS  DDLS  DDLX  DEVC  DOMA  DTEL  ENHO  ENHS
ENQU  FUGR  FUNC  HTTP  INTF  MSAG  NROB  SRVB  SRVD  TABL
TTYP  XSLT  TRAN  SCO1  SCO2  SCO3  SIA1  SIA6  SIA8  SMTG
```

**รายการทั้งหมด 75 ตัว**

| Code | Description | Code | Description |
|------|-------------|------|-------------|
| `APIS` | API Release State of Objects | `SAJC` | Application Job Catalog Entry |
| `APLO` | Application Log Object | `SAJT` | Application Job Template |
| `AUTH` | Authorization Check Fields | `SCO1` | Communication Scenario |
| `BDEF` | Behavior Definition | `SCO2` | Inbound Service |
| `BGQC` | Background Processing Context | `SCO3` | Outbound Service |
| `CDBO` | Customer Data Browser Object | `SIA1` | Business Catalog |
| `CFDF` | Custom Field | `SIA2` | Restriction Type |
| `CHDO` | Change Documents Object | `SIA3` | Authorization Object Extension |
| `CHKC` | ATC Check Category | `SIA5` | Restriction Field |
| `CHKO` | ATC Check Object | `SIA6` | IAM: App |
| `CHKV` | ATC Check Variant | `SIA7` | Business Catalog App Assignment |
| `CLAS` | Class | `SIA8` | Business Role Template |
| `COTA` | Connection Target Transport Object | `SIA9` | Business Role Template Business Catalog Assignment |
| `DCLS` | ABAP Data Control Language Sources | `SIAD` | Business Role Template Fiori Space Assignment |
| `DDLS` | Data Definition Language Source | `SKTD` | Knowledge Transfer Document |
| `DDLX` | CDS Metadata Extensions | `SMBC` | Maintainable Business Configuration |
| `DESD` | Logical External Schema | `SMTG` | OM: Email Template |
| `DEVC` | Package | `SOD1` | API Package |
| `DOMA` | Domain | `SOD2` | API Package Assignment |
| `DRAS` | CDS Aspects | `SRVB` | Service Binding |
| `DRTY` | Dictionary: CDS Type Definitions | `SRVD` | Service Definition |
| `DSFD` | CDS Scalar Function Definition | `SUCO` | Authorization Default Variant |
| `DSFI` | CDS Scalar Function Implementation Reference | `SUSH` | Authorization Default Values |
| `DTEB` | Dictionary Tuning: Entities Buffer | `SUSO` | Authorization Object |
| `DTEL` | Data Element | `SWCR` | Software Component Relations |
| `DTIX` | Entity Index | `TABL` | Table Definition |
| `EEEC` | Enterprise Event Enablement - Event Consumer | `TRAN` | Transaction |
| `ENHO` | Enhancement Implementation Object | `TTYP` | Table Type |
| `ENHS` | Enhancement Spot Implementation Object | `UIPG` | Fiori Launchpad Page Template |
| `ENQU` | Lock Object | `UIST` | Fiori Launchpad Space Template |
| `EVTB` | Event Binding | `XSLT` | Transformation |
| `FUGR` | Function Group | | |
| `FUNC` | Function Module | | |
| `GSMP` | Metric Provider | | |
| `HTTP` | HTTP Service | | |
| `INTF` | Interface | | |
| `INTM` | Intelligent Scenario Model | | |
| `INTS` | Intelligent Scenario | | |
| `MSAG` | Message Class | | |
| `NONT` | SAP Object Node Type | | |
| `NROB` | Number Range Object | | |
| `NTTY` | Note Type | | |
| `RONT` | SAP Object Type | | |
| `RVBC` | Review Booklet Configuration Model | | |

> หน้าเว็บของ SAP มี `CHDO` ซ้ำ 2 บรรทัด — ตัดออกแล้ว เหลือ 75 unique
>
> แก้ typo ของ SAP 3 จุด (ยืนยันแล้วว่าให้แก้ เพราะ description จะไปโผล่บน UI):
> `Dfinitions` → `Definitions` · `Intellligent` → `Intelligent` · `Maintanable` → `Maintainable`

### 6.6 Transport Type — `YRICEFW_TTYP_VH` ✨ ใหม่

| Code | Description | ใช้ที่ | sort | active |
|------|-------------|--------|------|--------|
| `WB` | Workbench Request | ทั้ง 2 edition | 10 | X |
| `CUS` | Customizing Request | ทั้ง 2 edition | 20 | X |
| `TOC` | Transport of Copies | Private Edition | 30 | X |
| `SC` | Software Collection | Public Edition | 40 | X |

### 6.7 Transport Status — `YRICEFW_TRST_VH` ✨ ใหม่

| Code | Description | sort | criticality | active |
|------|-------------|------|-------------|--------|
| `MOD` | Modifiable | 10 | 0 Neutral | X |
| `REL` | Released | 20 | 0 Neutral | X |
| `IMP` | Imported | 30 | 3 Positive | X |
| `ERR` | Import Error | 40 | 1 Negative | X |

`ERR` เป็นสถานะเดียวที่ต้องมีคนเข้าไปแก้จริงๆ จึงเป็นสีแดง

---

## 7. ✅ แยก `ricefw_type` ออกจาก `delivery_type` — เสร็จแล้ว

**ที่มา**: ค่าที่ตั้งใจใส่ใน `ricefw_type` (`NEW`/`LS`/`REM`) เป็น**แนวทางส่งมอบ** ไม่ใช่
**ประเภท RICEFW** — ทำให้ในโมเดลไม่มีที่เก็บ R/I/C/E/F/W เลย จึงแยกเป็น 2 field

| Field | เก็บอะไร | Code list |
|-------|---------|-----------|
| `ricefw_type` | ประเภท RICEFW — เป็นงานชนิดไหน | `RPT` `INTF` `CONV` `ENH` `FORM` `WF` |
| `delivery_type` | แนวทางส่งมอบ — ทำยังไงกับมัน | `NEW` `LS` `REM` |

2 มิตินี้ตั้งฉากกัน — Report ตัวหนึ่งอาจเป็น `NEW` อีกตัวเป็น `LS` ได้
แยก field แล้วกรองไขว้ได้ เช่น *"Interface ทั้งหมดที่ต้อง Remediate"*

### 7.1 Object ที่ต้องเพิ่ม / แก้

| Object | ทำอะไร |
|--------|--------|
| `YD_DELIVERY_TYPE` | ✅ CHAR 6 · Value Table = `YRICEFW_DTYP_VH` |
| `YE_DELIVERY_TYPE` | ✅ สร้างแล้ว |
| `YRICEFW_DTYP_VH` | ✅ check table (มี `invertedIndividualIndex`) |
| `YRICEFW_DTYP_VHT` | ✅ text table |
| `YRICEFW_HDR` | ✅ เพิ่ม field `delivery_type` ต่อจาก `ricefw_type` แล้ว |
| `YD_RICEFW_TYPE` | **ไม่ต้องแก้** — CHAR 6 รองรับ `RPT`…`WF` ได้อยู่แล้ว |

### 7.2 `YRICEFW_HDR` โครงสร้างใหม่

```abap
key client            : abap.clnt not null;
key ricefw_uuid       : sysuuid_x16 not null;

ricefw_id             : ye_ricefw_id;
ricefw_type           : ye_ricefw_type;        -- เปลี่ยนความหมาย เป็น R/I/C/E/F/W
delivery_type         : ye_delivery_type;      -- ใหม่
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
```

### 7.3 ลำดับชั้นที่ได้

```
YRICEFW_HDR   ricefw_type   = INTF   ← เป็นงานประเภทอะไร
              delivery_type = NEW    ← ส่งมอบยังไง
    └── YRICEFW_OBJ
              object_type   = CLAS   ← ประกอบด้วย object เทคนิคอะไรบ้าง
              object_type   = SRVB
              object_type   = DDLS
```

1 RICEFW item = 1 งานทางธุรกิจ ที่ประกอบด้วย object เทคนิคหลายตัว

---

## 8. ✅ Transport Table — รองรับทั้ง Private และ Public Edition

### 8.1 โจทย์: กลไกขนย้ายไม่เหมือนกัน

| | Private Edition | Public Edition |
|---|---|---|
| หน่วยพัฒนา | Workbench / Customizing Request | Workbench Request (dev extensibility) |
| หน่วยส่งมอบ | Transport Request คือหน่วยเดียวกัน | **Software Collection** ห่อ TR อีกชั้น |
| รูปแบบ ID | `S4DK900123` (10 ตัว) | ชื่อที่ตั้งเอง ยาวกว่า |
| การ import | STMS ทำเอง | SAP จัดการผ่าน pipeline |

ถ้าออกแบบ table ให้ล็อกกับกลไกใดกลไกหนึ่ง จะใช้กับอีก edition ไม่ได้

### 8.2 แนวทาง: อย่าจำลองกลไก ให้บันทึก "รายการ" แทน

ใช้ **field discriminator บอกชนิด** (`transport_type`) + **field ID แบบ generic** (`transport_id`)
โครงสร้างเดียวรองรับทั้งคู่โดยไม่ต้องมี logic แยก

```
Private Edition → บันทึก WB/CUS + เลข TR
Public Edition  → บันทึก WB + เลข TR  และ  SC + ชื่อ Software Collection
```

RICEFW หนึ่งรายการมีได้หลาย record ทั้งต่างชนิดและต่างรอบ

**DDL ของ `YRICEFW_TRSP` อยู่ใน `phase2_spec.md` §4**

### 8.2.1 ทำไมพัฒนาบน Public Edition แล้วย้ายไป Private Edition ได้

**released-object set ของ Public Edition แคบกว่า Private Edition** — อะไรที่ activate ผ่าน
บน Public Edition จึงย้ายไป PCE ได้เกือบแน่นอน แต่**ทางกลับกันไม่จริง**
(ของที่ใช้ได้บน PCE อาจไม่ released บน Public Edition)

หลักที่ยึดเพื่อรักษา portability:
- ใช้ **ABAP for Cloud Development** เท่านั้น ไม่แตะ classic ABAP
- **ห้ามอ่าน table ของระบบขนย้าย** (`E070`/`E071`) — มีเฉพาะ PCE
- ห้ามเรียก API ที่มีเฉพาะ edition ใด edition หนึ่ง
- code list เก็บใน customized table ไม่พึ่ง table มาตรฐานของ SAP ที่อาจต่างกันระหว่าง edition

### 8.3 ⚠️ ข้อจำกัด: ต้องกรอกเอง

**ตารางนี้เป็นบันทึกที่ user กรอก ไม่ได้อ่านจากระบบขนย้ายจริง** — ยืนยันแล้วว่ารับได้

บน Public Edition อ่าน `E070`/`E071` ไม่ได้ (ไม่ใช่ released object) และ API ของ Software Collection
ก็ต่างจาก Private Edition คนละเรื่อง — ถ้าจะดึงอัตโนมัติต้องเขียนโค้ดคนละชุดต่อ edition
ซึ่งขัดกับเป้าหมายที่วางไว้

**ทางออกในอนาคต** ถ้ามี API ที่ดึงข้อมูล Software Collection / Transport Request บน Public Edition ได้:
ทำเป็น interface + implementation แยกต่อ edition แล้ว inject เข้ามา — **โครง table ไม่ต้องแก้เลย**

### 8.4 ตัดสินใจแล้ว: ไม่ทำตารางเชื่อม object × transport

ถ้าอยากรู้ว่า object ตัวไหนอยู่ใน TR ไหน จะต้องมีตารางเชื่อมอีกชั้น — **ไม่ทำ**
เพราะในทางปฏิบัติดูที่ระดับ RICEFW ว่า "งานนี้อยู่ใน TR ไหนบ้าง" ก็พอ
ถ้าต้องรู้ถึงระดับ object ก็เปิดดูใน TR เอาได้

---

## 9. ✅ Class Generator — `YCL_RICEFW_VH_GEN`

Class เดียวรัน 7 methods โหลดค่าเข้าทั้ง 14 tables — **idempotent** (`DELETE` แล้ว `INSERT` ทุกครั้ง
รันซ้ำได้เสมอ) และ `COMMIT WORK` ครั้งเดียวตอนจบ (`main`) เพื่อให้เป็น all-or-nothing

```
รันผ่าน: right-click → Run As → ABAP Application (Console)  (หรือ F9)

ผลลัพธ์ที่ควรได้:
  YRICEFW_TYPE_VH        6 codes   12 texts
  YRICEFW_DTYP_VH        3 codes    6 texts
  YRICEFW_STAT_VH       10 codes   20 texts
  YRICEFW_ROLE_VH        4 codes    8 texts
  YRICEFW_OTYP_VH       75 codes  150 texts
  YRICEFW_TTYP_VH        4 codes    8 texts
  YRICEFW_TRST_VH        4 codes    8 texts

รวม 106 check + 212 text = 318 records
```

**Language key ที่ใช้**: `E` (English) และ `2` (Thai) — ทั้งสองภาษาใช้ description เดียวกัน
ไว้แปลไทยจริงทีหลังแค่แก้ constant `gc_lang_th` ถ้า key ผิด

---

## 10. ✅ CDS Value Help Views — ครบ 7 ตัว

Interface view (`YI_*_VH`) join check table กับ text table ผ่าน `$session.system_language`
กรอง `is_active = 'X'` ที่ WHERE — โครงเดียวกันทุกตัว ต่างกันแค่มี/ไม่มี `Criticality`

| # | View | Table คู่ | Criticality | sizeCategory |
|---|------|----------|:-----------:|:---:|
| 1 | `YI_RICEFW_TYPE_VH` | `YRICEFW_TYPE_VH/VHT` | ❌ | `#XS` |
| 2 | `YI_RICEFW_STAT_VH` | `YRICEFW_STAT_VH/VHT` | ✅ | `#XS` |
| 3 | `YI_RICEFW_ROLE_VH` | `YRICEFW_ROLE_VH/VHT` | ❌ | `#XS` |
| 4 | `YI_RICEFW_OTYP_VH` | `YRICEFW_OTYP_VH/VHT` | ❌ | `#XS` |
| 5 | `YI_RICEFW_TTYP_VH` | `YRICEFW_TTYP_VH/VHT` | ❌ | `#XS` |
| 6 | `YI_RICEFW_TRST_VH` | `YRICEFW_TRST_VH/VHT` | ✅ | `#XS` |
| 7 | `YI_RICEFW_DTYP_VH` | `YRICEFW_DTYP_VH/VHT` | ❌ | `#XS` |

### ตัวอย่าง (มี criticality) — `YI_RICEFW_STAT_VH`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Overall Status - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity YI_RICEFW_STAT_VH
  as select from yricefw_stat_vh as Status
  inner join   yricefw_stat_vht as Text
    on  Text.overall_status = Status.overall_status
    and Text.spras          = $session.system_language
{
  key Status.overall_status as OverallStatus,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description       as Description,

      Status.sort_order       as SortOrder,
      Status.criticality      as Criticality
}
where
  Status.is_active = 'X'
```

อีก 6 ตัวโครงเดียวกัน เปลี่ยนแค่ชื่อ table/field และตัด `Criticality` ออกถ้าไม่มี

### 10.1 Naming convention ที่วางไว้จากตัวแรก

**DB table = `snake_case` เสมอ, CDS element = `UpperCamelCase` เสมอ** — ตาม pattern ของ
ABAP Flight Reference Scenario (`CARRID` → `AirlineID`) จะใช้กับทุก view ตั้งแต่ Phase 4 เป็นต้นไป

### 10.2 ⚠️ 2 บทเรียนที่เจอระหว่างสร้าง (บันทึกลง memory แล้ว)

**`ORDER BY` ใช้ในตัว View Entity ไม่ได้** — CDS มองผลลัพธ์เป็น set ที่ไม่มีลำดับตามหลัก
relational model ตอนแรกวางแผนไว้ (§ก่อนหน้า) ว่าจะ sort ด้วย `ORDER BY` แต่ activate ไม่ผ่าน
(*"Unexpected keyword order"*) — เอา `SortOrder` field ไว้ในผลลัพธ์เฉยๆ แล้วค่อยคุมการเรียง
ที่ metadata extension (`@UI.presentationVariant`) ตอน Phase 6/7 แทน

**`@ObjectModel.resultSet.sizeCategory` มีแค่ 2 ค่า: `#XS` และ `#XXS`** — ไม่มี `#S`/`#M`/`#L`/`#XL`
ตามที่คาดเดาได้จากชื่อ enum ใส่ `#S` แล้ว activate error *"Invalid annotation enum value"*
ยืนยันด้วย Ctrl+Space ใน ADT — ใช้ `#XS` กับทุก view ในโปรเจกต์นี้ (ผลลัพธ์เล็กสุด 3 แถว
ใหญ่สุด 30 แถวหลัง filter ก็ยังเหมาะกับ `#XS`)

annotation นี้เป็นแค่ hint บอก Fiori Elements ว่าควรโหลดผลลัพธ์มาแสดงทีเดียวหมดหรือทำ paging
ไม่กระทบความถูกต้องของข้อมูล ใส่ผิดก็แค่ UX ไม่เหมาะ ไม่ error ไม่ dump

---

## 11. Checklist

- [x] `YRICEFW_TYPE_VH` · `YRICEFW_TYPE_VHT`
- [x] `YRICEFW_STAT_VH` · `YRICEFW_STAT_VHT`
- [x] `YRICEFW_ROLE_VH` · `YRICEFW_ROLE_VHT`
- [x] `YRICEFW_OTYP_VH` · `YRICEFW_OTYP_VHT`
- [x] Activate ครบ 8 ตัว — check table ทั้ง 4 ต้องเติม `invertedIndividualIndex` (§2.1)
- [x] ใส่ Value Table ที่ domain ทั้ง 4 — activate ผ่านทั้งหมด
- [x] ยืนยันค่าที่จะ load ครบทั้ง 5 กลุ่ม (§6)
- [x] **แยก `delivery_type` ออกมา** (§7) — 4 object ใหม่ + แก้ `YRICEFW_HDR`
- [x] ใส่ Value Table ที่ `YD_DELIVERY_TYPE`
- [x] **Transport (§8)** — 3 domains + 3 data elements + `YRICEFW_TRSP` + 4 value help tables
- [x] ใส่ Value Table ที่ `YD_TRANSPORT_TYPE` · `YD_TRANSPORT_STATUS`
- [x] Class generator `YCL_RICEFW_VH_GEN` — load ค่าทั้ง 7 กลุ่ม 318 records (§9)
- [x] CDS view 7 ตัว (§10) — activate ผ่านครบ

**Phase 3 จบแล้ว ✅**
