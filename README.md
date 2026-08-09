# demo-yricefw

RAP UI app สำหรับบริหารจัดการ **RICEFW objects** (Reports, Interfaces, Conversions,
Enhancements, Forms, Workflows) ในโครงการ SAP implementation

| | |
|---|---|
| ประเภทงาน | Demo app |
| ABAP Package | `YRICEFW` |
| Target system | SAP S/4HANA Cloud Public Edition |
| ABAP Language Version | ABAP for Cloud Development (Clean Core) |
| Architecture | RAP — Managed BO, Draft-enabled |
| UI | SAP Fiori Elements (List Report + Object Page), OData V4 |

> ออกแบบให้ย้ายไป **Private Edition** ได้โดยไม่ต้องแก้ — ใช้เฉพาะ ABAP for Cloud Development
> ไม่อ่าน table ของระบบขนย้าย ไม่เรียก API ที่มีเฉพาะ edition ใด edition หนึ่ง

## Business Object

```
YR_RICEFW (Root — RICEFW Master)
├── _Owner     : composition [0..*] → YI_RICEFW_OWNER
├── _Object    : composition [0..*] → YI_RICEFW_OBJECT
└── _Transport : composition [0..*] → YI_RICEFW_TRANSPORT
```

**1 RICEFW item = 1 งานทางธุรกิจ** ที่มีผู้รับผิดชอบหลายคน ประกอบด้วย object เทคนิคหลายตัว
และเดินทางขึ้นระบบผ่าน transport หลายรอบ

| Entity | เก็บอะไร |
|--------|---------|
| Master | ประเภท RICEFW · แนวทางส่งมอบ · สถานะรวม · แผนวันที่ |
| Owner | ผู้รับผิดชอบ + บทบาท + ความคืบหน้า |
| Object | ABAP object ที่ประกอบกันเป็นงานนี้ |
| Transport | Transport Request / Software Collection ที่เกี่ยวข้อง |

## Progress

| Phase | สถานะ |
|-------|-------|
| 0 — Project & Package Setup | ✅ |
| 1 — Domains & Data Elements | ✅ 9 + 9 |
| 2 — Database Tables | ✅ 4 transaction tables |
| 3 — Value Help Tables + Views | 🔄 14 tables ✅ · generator + CDS view ยังไม่ทำ |
| 4 — CDS Data Model | ⏳ |
| 5 — Behavior Definition & Implementation | ⏳ |
| 6 — Projection Views | ⏳ |
| 7 — Metadata Extensions | ⏳ |
| 8 — Service Exposure | ⏳ |
| 9 — Security & Finishing | ⏳ |

**36 objects** — 9 domains · 9 data elements · 4 transaction tables · 14 value help tables

## Design หลักที่ยึด

**Technical key = UUID** ทุก table · `ricefw_id` เป็น free text ที่ user กรอกเอง จึงใช้เป็น
foreign key ไม่ได้ (user แก้ได้ตลอด และตอน create ยังว่างอยู่)

**Code list เก็บใน table ไม่ใช่ domain fixed values** — 7 code lists แต่ละตัวมี check table
คู่กับ text table ที่แปลภาษาได้ แก้ค่าได้โดยไม่ต้องแตะ DDIC และ repo นี้เลยเป็นตัวอย่าง
ของ pattern นี้ไปในตัว

**Object type อ้างอิง SAP มาตรฐาน** — 75 ค่าจาก [Released ABAP Object Types](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/b31aa03640b940d5981ce2af1cd0a019.html)
โหลดครบทั้งหมด แต่เปิดใช้ 30 ตัวผ่าน `is_active` เพื่อให้ dropdown ใช้งานได้จริง

**Transport รองรับ 2 edition ด้วยโครงเดียว** — `transport_type` เป็น discriminator
(`WB`/`CUS`/`TOC` = Transport Request · `SC` = Software Collection) แทนที่จะจำลองกลไก
ของ edition ใดเป็นการเฉพาะ

## เอกสาร

| File | เนื้อหา |
|------|---------|
| [docs/design.md](docs/design.md) | Data model · naming convention · implementation plan 10 phase · decisions log |
| [docs/phase1_spec.md](docs/phase1_spec.md) | Domains + Data Elements |
| [docs/phase2_spec.md](docs/phase2_spec.md) | Transaction tables (DDL) |
| [docs/phase3_spec.md](docs/phase3_spec.md) | Value help tables (DDL) + ค่าที่ load + เหตุผลการออกแบบ |

## abapGit

`src/` เป็นของ abapGit ทั้งหมด — serialize จาก package `YRICEFW` ในระบบ SAP
`README.md` และ `docs/` อยู่นอก starting folder abapGit ไม่แตะ
