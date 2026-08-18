# `YCL_RICEFW_GEN` — Demo Data Generator

Console class (`IF_OO_ADT_CLASSRUN`) สร้างชุดข้อมูลตัวอย่างสำหรับทดลองใช้งานแอปและดูพฤติกรรม
ของ UI ที่ต้องมีข้อมูลระดับหนึ่งถึงจะเห็นผล (สี criticality, การเรียงลำดับ, responsive popin,
progress bar)

**รันซ้ำได้เสมอ** — ล้างของเดิมทั้งหมดก่อนสร้างใหม่ทุกครั้ง

---

## 1. ⚠️ ข้อจำกัดที่กำหนดโครงสร้างของ class: ต้องแยก 2 จังหวะ

`setInitialStatus` (determination `on modify { create; }` จาก Phase 5.2) **บังคับ
`OverallStatus = 'OPN'` ทุกครั้งที่ create** — ระบุค่าอื่นตอนสร้างไปก็ถูกทับ

ถ้าอยากได้ข้อมูลที่กระจายครบทุก status ต้องทำ 2 จังหวะ:

| จังหวะ | ทำอะไร |
|---|---|
| 1 | `CREATE` root + owner + transport (deep create) → `COMMIT` · ทุกตัวได้ `OPN` |
| 2 | `UPDATE FIELDS ( OverallStatus )` ตามค่าจริง → `COMMIT` |

> **ทางเลือกที่ไม่เลือก**: `INSERT` ลงตารางตรงๆ เร็วกว่าและคุมทุก field ได้ แต่ข้ามทั้ง
> validation และ determination — ข้อมูลที่ได้จะไม่ผ่านกฎของ BO ซึ่งขัดกับจุดประสงค์ที่อยาก
> ให้ข้อมูลทดสอบสะท้อนพฤติกรรมจริงของแอป

---

## 2. ชุดข้อมูล

### 2.1 RICEFW Master (10 รายการ — status ไม่ซ้ำกันเลย)

prefix ตีความตามธรรมเนียม SAP (module + ประเภทงาน) แล้วเขียน description ให้สอดคล้อง

| # | RICEFW ID | Type | Delivery | Description | Overall Status |
|---|---|---|---|---|---|
| 1 | `YSDR001` | RPT | NEW | Sales Order Backlog Report | 🟢 `CLS` Done |
| 2 | `YSDR002` | RPT | NEW | Customer Billing Summary Report | ⬜ `UAT` User Testing |
| 3 | `YSDR003` | RPT | NEW | Delivery Performance Report | ⬜ `DEV` In Development |
| 4 | `YMMI001` | INTF | NEW | Vendor Master Data Inbound Interface | ⬜ `SIT` Integration Testing |
| 5 | `YMMI002` | INTF | NEW | Purchase Order Outbound Interface to Supplier Portal | 🟡 `HLD` On Hold |
| 6 | `YMMI003` | INTF | NEW | Goods Receipt Confirmation Interface | ⬜ `PND` Pending |
| 7 | `YFIE001` | ENH | NEW | Custom Field Validation on Journal Entry | ⬜ `FAT` Functional Testing |
| 8 | `YFIE002` | ENH | NEW | Automatic Cost Center Derivation Enhancement | ⬜ `UT` Unit Testing |
| 9 | `YFIE003` | ENH | NEW | Payment Terms Check on Vendor Invoice | 🔴 `CAN` Cancelled |
| 10 | `YFIF001` | FORM | NEW | Customer Invoice Print Form | 🟡 `OPN` Not Assigned |

**หลักการจัด**: เลข `001` ก้าวหน้าที่สุดในแต่ละกลุ่มแล้วไล่ถอยลง · กระจายไม่ให้ type เดียวกัน
กองอยู่ช่วง status ติดกัน

### 2.2 Plan Start / Plan Finish

จงใจให้ 3 ตัวเลยกำหนด (อ้างอิงวันปัจจุบัน ส.ค. 2026) เพื่อทดสอบฟีเจอร์ "Overdue" ในอนาคต

| Status | Plan Start | Plan Finish | |
|---|---|---|---|
| `CLS` | 2026-01-05 | 2026-03-31 | จบไปแล้ว |
| `HLD` | 2026-02-02 | 2026-06-30 | **เลยกำหนด** |
| `CAN` | 2026-03-02 | 2026-07-31 | **เลยกำหนด** (ยกเลิกแล้ว) |
| `UAT` | 2026-03-16 | 2026-08-31 | ใกล้ครบกำหนด |
| `SIT` | 2026-04-13 | 2026-09-30 | |
| `FAT` | 2026-05-11 | 2026-10-30 | |
| `UT` | 2026-06-15 | 2026-11-30 | |
| `DEV` | 2026-07-13 | 2026-12-31 | |
| `PND` | 2026-08-17 | 2027-01-29 | |
| `OPN` | 2026-09-14 | 2027-02-26 | ยังไม่เริ่ม |

### 2.3 Transport (2 รายการต่อ RICEFW = 20)

| Overall Status | WB | CUS | เหตุผล |
|---|---|---|---|
| `OPN` `PND` `DEV` `UT` | `MOD` | `MOD` | ยังพัฒนา/เทสในระบบ DEV ยังไม่ปล่อย |
| `FAT` | `REL` | `REL` | ปล่อยแล้ว รอ/กำลังย้ายไป QA |
| `SIT` `UAT` `CLS` | `IMP` | `IMP` | import เข้าปลายทางเรียบร้อย |
| **`HLD`** | 🔴 `ERR` | `IMP` | **import พัง เลยต้องพักงานไว้** |
| `CAN` | `MOD` | `MOD` | ยกเลิกก่อนปล่อย |

`HLD` เป็นจุดเดียวที่ WB กับ CUS ต่างกัน — จงใจให้มีเรื่องเล่า (งานค้างเพราะ transport พัง)
และเป็นที่เดียวที่ได้เห็น `ERR` สีแดง ทำให้ครบทั้ง 4 transport status

| Field | รูปแบบ | ตัวอย่าง |
|---|---|---|
| Transport ID | `S4DK9001nn` เรียงต่อกัน 20 เลข | `S4DK900101` |
| Description (WB) | `AB: <ID> V1.0` | `AB: YSDR001 V1.0` |
| Description (CUS) | `AB: Constant Parameter for <ID> V1.0` | `AB: Constant Parameter for YSDR001 V1.0` |
| Import Sequence | WB = 1 · CUS = 2 | |
| Released On | เติมเฉพาะ status ที่ไม่ใช่ `MOD` | |

### 2.4 Owner (2 คนต่อ RICEFW = 20)

| # | RICEFW ID | `AB` ABAP Developer | `FN` Functional Consultant |
|---|---|---|---|
| 1 | `YSDR001` | Baramee Sukhong | James Carter |
| 2 | `YSDR002` | Chawanat Nimphung | Emily Brooks |
| 3 | `YSDR003` | Chayaporn Ditsakul | Michael Reed |
| 4 | `YMMI001` | Kwankamon Tansopaluck | Sarah Mitchell |
| 5 | `YMMI002` | Napat Wichaisuttigul | David Foster |
| 6 | `YMMI003` | Navapat Tongpubet | Laura Bennett |
| 7 | `YFIE001` | Parinya Kijwattanaboon | Robert Hayes |
| 8 | `YFIE002` | Saran Trakarnvanich | Jennifer Walsh |
| 9 | `YFIE003` | Tanet Juengtavonanan | Daniel Prescott |
| 10 | `YFIF001` | Thatpicha Wongsa | Karen Sullivan |

Owner ID: `ABAP01`–`ABAP10` · `FUNC01`–`FUNC10`

### 2.5 Progress — ABAP กับ FN ไม่เท่ากันโดยตั้งใจ

| Status | FN | AB | เหตุผล |
|---|---|---|---|
| `OPN` | 0 | 0 | ยังไม่เริ่มทั้งคู่ |
| `PND` | **10** | 0 | FN เริ่มเก็บ requirement · ABAP ยังไม่แตะ |
| `DEV` | **50** | 35 | spec เกือบเสร็จ · code เพิ่งเริ่ม |
| `UT` | 60 | **70** | ABAP แซง — unit test เป็นงานของ ABAP |
| `FAT` | 75 | **80** | |
| `SIT` | 85 | 85 | เท่ากัน ทดสอบร่วมกัน |
| `UAT` | 90 | **95** | |
| `CLS` | 100 | 100 | จบทั้งคู่ |
| `HLD` | 50 | **60** | dev เสร็จแล้ว ติดที่ deploy → ABAP นำ |
| `CAN` | **25** | 15 | ยกเลิกตอน scope review — FN ทำ analysis ไปแล้ว |

**หลักการ**: FN นำช่วงต้น (analysis/spec) · ABAP นำช่วงพัฒนาและ deploy · ผลคือเห็น progress bar
สองแท่งไม่เท่ากันในตารางเดียว ซึ่งสมจริงกว่าให้เท่ากันหมด

### 2.6 Remark

เว้นว่างเป็นส่วนใหญ่ ใส่เฉพาะ 2 ตัวที่ต้องมีคำอธิบาย:

| ID | Remark |
|---|---|
| `YMMI002` (HLD) | Blocked by failed transport import in QA. Waiting for basis team. |
| `YFIE003` (CAN) | Cancelled after scope review - covered by standard configuration. |

### 2.7 RICEFW Object

**ไม่สร้าง** ตาม spec — เว้นไว้ทดสอบการเพิ่มด้วยมือบน UI

---

## 3. โครงสร้าง class

| Method | หน้าที่ |
|---|---|
| `build_seed` | **ชุดข้อมูลทั้งหมดอยู่ที่นี่ที่เดียว** — แก้ข้อมูลแก้ที่นี่ |
| `delete_all` | ลบ RICEFW ทั้งหมด (cascade ลบ child เองผ่าน composition) |
| `create_all` | deep create 10 root + 20 owner + 20 transport ใน `MODIFY ENTITIES` เดียว |
| `update_status` | `UPDATE` `OverallStatus` ตามค่าจริง แล้วพิมพ์สรุปผล |

แยก **ข้อมูล** ออกจาก **logic** เพื่อให้ปรับชุดข้อมูลได้โดยไม่ต้องแตะโค้ด EML

---

## 4. 💡 บทเรียน: `TYPE TABLE FOR CREATE <root>\<assoc>`

ต่างจาก smoke test (phase5_spec.md §5.7) ที่ใช้ `VALUE #( ... )` แบบ inline — พอมีข้อมูล 10 ชุด
การเขียน inline อ่านไม่ไหว จึงใช้ **typed table** สร้างล่วงหน้าใน `LOOP` แล้วส่งเข้า EML ด้วย `WITH`

```abap
DATA lt_root      TYPE TABLE FOR CREATE yr_ricefw.
DATA lt_owner     TYPE TABLE FOR CREATE yr_ricefw\_Owner.
DATA lt_transport TYPE TABLE FOR CREATE yr_ricefw\_Transport.

" ... เติมข้อมูลใน LOOP ...

MODIFY ENTITIES OF yr_ricefw
  ENTITY RicefwMaster
    CREATE FIELDS ( ... ) WITH lt_root
    CREATE BY \_Owner     FIELDS ( ... ) WITH lt_owner
    CREATE BY \_Transport FIELDS ( ... ) WITH lt_transport
  MAPPED DATA(ls_mapped) FAILED DATA(ls_failed) REPORTED DATA(ls_reported).
```

**โครงสร้าง 2 ชั้นยังเหมือนเดิม** — row ของ `lt_owner` มี `%cid_ref` ชี้กลับไปที่ root และ
`%target` เป็น internal table ของ child จริง (ดู phase5_spec.md §5.7 สำหรับที่มาของ `%target`)

**รันผ่านครั้งแรกโดยไม่ต้องแก้อะไรเลย** — ต่างจาก smoke test ที่กว่าจะได้ `%target` ต้องเดาผิด
2 รอบ · เพราะรอบนี้มี pattern ที่พิสูจน์แล้วเป็นฐาน

**deep create 10 root + 40 child ในคำสั่งเดียวทำได้จริง** ไม่ต้องวน loop เรียก EML ทีละตัว

---

## 5. วิธีใช้

รันผ่าน ADT: คลิกขวาที่ class → **Run As → ABAP Application (Console)** (หรือ `F9`)

```
=== RICEFW Demo Data Generator ===
ไม่มีข้อมูลเดิม — เริ่มสร้างได้เลย
สร้างแล้ว: 10 RICEFW · 20 owner · 20 transport
ตั้ง OverallStatus แล้ว 10 รายการ

--- ผลลัพธ์ ---
YFIE001   ENH   FAT  Custom Field Validation on Journal Entry
YFIE002   ENH   UT   Automatic Cost Center Derivation Enhancement
...
=== Done ===
```

⚠️ **ลบข้อมูลเดิมทั้งหมดทุกครั้งที่รัน** — ถ้ามี record ที่สร้างเองบน UI แล้วอยากเก็บไว้
อย่ารัน class นี้

---

## 6. สิ่งที่ยืนยันได้จากข้อมูลชุดนี้บน UI

| ฟีเจอร์ | เห็นผลที่ไหน |
|---|---|
| Criticality | 🟢 `CLS` · 🔴 `CAN` · 🟡 `OPN`/`HLD` · เทาที่เหลือ — ครบในหน้าเดียว |
| Text arrangement 2 แบบ | Type = `Report` (`#TEXT_ONLY`) · Status = `Done (CLS)` (`#TEXT_FIRST`) |
| `presentationVariant` | เรียงตาม RICEFW ID อัตโนมัติ |
| Value help sort | dropdown เรียงตาม `sort_order` ไม่ใช่ตัวอักษร |
| `importance` + responsive popin | จอแคบ: 4 คอลัมน์ `#HIGH` อยู่รอด · 3 คอลัมน์ `#MEDIUM` ย้ายไปเป็นบรรทัดย่อย |
| Progress bar | `YMMI002` แสดง 60 vs 50 สองแท่งไม่เท่ากัน |
| `multiLineText` | Remark ของ `YMMI002` แสดงหลายบรรทัด |
| Transport criticality | `YMMI002` มี 🔴 Import Error คู่กับ 🟢 Imported ในตารางเดียว |
