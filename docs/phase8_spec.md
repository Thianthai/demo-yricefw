# Phase 8 — Service Exposure ✅

Package: `YRICEFW` · Service Definition + Service Binding — publish และ preview ผ่านจริง
**เป็น phase ที่เห็นหน้าจอ Fiori ครั้งแรก**

---

## 1. `YUI_RICEFW` — Service Definition

สร้างจาก: คลิกขวาที่ `YC_RICEFW` → **New Service Definition**

```abap
@EndUserText.label: 'RICEFW Management - Service Definition'
define service YUI_RICEFW {
  expose YC_RICEFW           as RicefwMaster;
  expose YC_RICEFW_OWNER     as RicefwOwner;
  expose YC_RICEFW_OBJECT    as RicefwObject;
  expose YC_RICEFW_TRANSPORT as RicefwTransport;

  expose YI_RICEFW_TYPE_VH as RicefwTypeVH;
  expose YI_RICEFW_DTYP_VH as DeliveryTypeVH;
  expose YI_RICEFW_STAT_VH as OverallStatusVH;
  expose YI_RICEFW_ROLE_VH as RoleVH;
  expose YI_RICEFW_OTYP_VH as ObjectTypeVH;
  expose YI_RICEFW_TTYP_VH as TransportTypeVH;
  expose YI_RICEFW_TRST_VH as TransportStatusVH;
}
```

### ⚠️ ต้อง expose value help view ด้วย ไม่งั้น F4 ตาย

`@Consumption.valueHelpDefinition` ที่ผูกไว้ตอน Phase 6 **จะไม่ทำงานเลยถ้า VH view ไม่ได้อยู่ใน
service** — กด F4 แล้วได้ dropdown ว่างหรือ error โดยไม่มีอะไรบอกสาเหตุ

เหตุผล: OData service คือ "กล่อง" ที่บอกว่ามี entity อะไรเข้าถึงได้บ้าง annotation ที่ชี้ไปหา
entity นอกกล่อง client เรียกไม่ได้

---

## 2. ⭐ กับดักใหญ่สุดของ phase นี้: alias + `Type` ห้ามชนกับชื่อ property

**ครั้งแรกตั้ง alias ว่า `Owner` / `Object` / `Transport` (ให้ตรงกับ bdef alias) แล้ว publish
ผ่าน แต่ `$metadata` พังทั้ง service**

```json
"code": "/IWBEP/CM_V4_MED/082",
"message": "Property 'TransportType' has the same EDM name as entity type 'TransportType'"
```

### กลไก

RAP สร้างชื่อ **EDM entity type** จาก alias โดย**เติมคำว่า `Type` ต่อท้ายอัตโนมัติ**

```
expose YC_RICEFW_TRANSPORT as Transport;
                               │
                               ├─→ entity set:  Transport
                               └─→ entity type: Transport + Type = TransportType   ← ชน
```

แล้ว `YC_RICEFW_TRANSPORT` ก็มี property ชื่อ `TransportType` อยู่พอดี — OData ห้ามชื่อซ้ำใน
namespace เดียวกัน metadata เลยประกอบไม่ได้ทั้ง service

### มี 2 จุดที่ชน แต่ error โชว์ทีละจุด

metadata generator หยุดที่ error แรกที่เจอ แก้ตัวเดียวแล้วจะไปโผล่อีกตัว:

| alias เดิม | entity type ที่ได้ | property ที่ชน | View |
|---|---|---|---|
| `Transport` | `TransportType` | `TransportType` | `YC_RICEFW_TRANSPORT` |
| `Object` | `ObjectType` | `ObjectType` | `YC_RICEFW_OBJECT` |

`Owner` → `OwnerType` ไม่ชน (ไม่มี property ชื่อนี้) แต่เปลี่ยนเป็น `RicefwOwner` ด้วยเพื่อความ
สม่ำเสมอ และกันไว้เผื่อวันหลังเพิ่ม field ชื่อ `OwnerType` แล้วพังย้อนหลัง

### กฎที่ต้องจำ

**`<alias>` + `Type` ต้องไม่ชนกับชื่อ property ใดๆ ใน service** — ซึ่งขัดกับสัญชาตญาณที่อยาก
ตั้ง alias สั้นๆ ให้ตรงกับ bdef alias พอดี · bdef alias กับ service alias เป็นคนละ namespace
**ไม่ต้องตรงกันก็ได้** และ MDE อ้าง association (`_Owner`) ไม่ได้อ้าง entity set name จึงไม่ต้อง
แก้ตามเลย

---

## 3. `YUI_RICEFW_O4` — Service Binding

สร้างจาก: คลิกขวาที่ `YUI_RICEFW` → **New Service Binding** (เป็น **form** ไม่ใช่ code)

| ช่อง | ค่า |
|---|---|
| Name | `YUI_RICEFW_O4` |
| Binding Type | **OData V4 - UI** |
| Service Definition | `YUI_RICEFW` |

⚠️ **ต้องเป็น "OData V4 - UI" ไม่ใช่ "Web API"** — Web API ไม่รองรับ draft handling เลือกผิดจะ
activate ผ่านแต่ preview พังหรือไม่มีปุ่ม Create/Edit

### Activate ≠ Publish

เป็นคนละขั้นตอนกัน ต้องทำครบทั้งสอง:

| ขั้น | ผล |
|---|---|
| Activate | object ถูกสร้างใน repository — **ยังไม่มี URL ให้เรียก** |
| **Publish** | สร้าง *local service endpoint* จริง → `$metadata` ถึงจะตอบ |

publish แล้ว `Local Service Endpoint` จะขึ้นว่า **Published** และปุ่มเปลี่ยนเป็น `Unpublish`

---

## 4. 💡 วิธี debug ที่ได้ผลจริง: เปิด `$metadata` ตรงๆ

ตอน preview พังครั้งแรก ทั้ง 2 หน้าจอที่ ADT เปิดให้บอกอะไรไม่ได้เลย:

| หน้าจอ | ข้อความ | มีประโยชน์ไหม |
|---|---|---|
| Fiori preview | *"Failed to load UI5 component for navigation intent #app-preview"* | ❌ ไม่บอกสาเหตุ |
| Swagger test client | `Not Found /testclient/...$metadata` | ❌ 404 ไม่บอกว่าทำไม |

**ทางที่ได้คำตอบ** — เปิด URL นี้ตรงๆ ในเบราว์เซอร์ที่ login ระบบอยู่แล้ว:

```
https://<host>/sap/opu/odata4/sap/yui_ricefw_o4/srvd/sap/yui_ricefw/0001/$metadata
```

ได้ JSON error ที่ระบุสาเหตุชัดเจนทันที (`Property 'TransportType' has the same EDM name...`)

**เหตุผลที่ต่างกัน**: Swagger รันบน `localhost:<port>` แล้วเรียกผ่าน path `/testclient/...`
ซึ่งเป็น **proxy ที่ ADT เปิดบนเครื่อง** ไม่ได้ยิงตรงไปที่ระบบ — error ที่แท้จริงถูกกลืนหายไป
กลายเป็น 404 เปล่าๆ

> **ยึดเป็นขั้นตอนมาตรฐาน**: preview พังเมื่อไหร่ ให้เปิด `$metadata` ตรงๆ ก่อนเสมอ
> อย่าไล่เดาจากหน้าจอ preview

---

## 5. รอบขัดหน้าจอ (UI polish) — 8 จุดที่แก้หลัง preview ครั้งแรก

### 5.1 Value help: ตัดคอลัมน์เกิน + เรียงให้ถูก

dropdown โชว์ 3 คอลัมน์ (code / text / **เลข sort**) และเรียงตาม key ตัวอักษรแทนลำดับที่ออกแบบไว้

แก้ที่ **VH view ทั้ง 7 ตัว**:

```abap
@UI.presentationVariant: [{ sortOrder: [{ by: 'SortOrder', direction: #ASC }] }]
define view entity YI_RICEFW_TYPE_VH
  ...
{
  key Type.ricefw_type as RicefwType,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description as Description,

      @UI.hidden: true
      Type.sort_order  as SortOrder
}
```

2 ตัวที่มี `Criticality` (`STAT_VH`, `TRST_VH`) ใส่ `@UI.hidden: true` ที่ `Criticality` ด้วย

ผลลัพธ์: `OPN → PND → DEV → UT → FAT → SIT → UAT → CLS → HLD → CAN` ตรงตาม `sort_order` 10–99

### 5.2 ⭐ Field ที่ใช้ built-in type ไม่มี label

**อาการ**: field โผล่มาไม่มีชื่อ หรือขึ้นว่า `undefined` บนหน้าจอ

**สาเหตุ**: Phase 1 สร้าง data element (`YE_*`) เฉพาะ field ที่มี code list ส่วน field อื่น
ประกาศเป็น built-in type ตรงๆ ซึ่ง**ไม่มี label ติดมา**

```abap
description  : abap.char(80);    ← ไม่มี label → ช่องไม่มีชื่อ
plan_start   : abap.datn;        ← ไม่มี label
progress     : abap.int1;        ← ไม่มี label → "undefined"
ricefw_type  : ye_ricefw_type;   ← มี data element → มี label ปกติ
```

**แก้ด้วย `@EndUserText.label` ที่ projection view** ไม่ต้องสร้าง data element ย้อนหลัง —
label เป็นเรื่องของชั้นการแสดงผล

| View | Field ที่ต้องใส่ label |
|---|---|
| `YC_RICEFW` | `Description` `PlanStart` `PlanFinish` `Remark` |
| `YC_RICEFW_OWNER` | `OwnerID` `OwnerName` `Progress` |
| `YC_RICEFW_OBJECT` | `ObjectName` `Description` |
| `YC_RICEFW_TRANSPORT` | `Description` `ImportSequence` `ReleasedOn` |

⚠️ **`OwnerName` ต้องใส่ทับแม้จะมี label อยู่แล้ว** — `vdm_userdescription` มี label ว่า
**"Description"** ซึ่งพอไปอยู่ในตาราง Owners อ่านแล้วงงมาก (คอลัมน์ที่ 2 ชื่อ "Description"
ทั้งที่เป็นชื่อคน)

### 5.3 รวมหลาย section ไว้ tab เดียว — `#COLLECTION` facet

เดิม facet 6 ตัว = 6 tab · ต้องการให้ General Information / Schedule / Administrative Data
อยู่ tab เดียวกันเป็น 3 section

**วิธี**: facet ตัวหนึ่งเป็น `type: #COLLECTION` (กล่องเปล่า ไม่ชี้ไปที่ข้อมูลใด) แล้วให้ facet
ลูกชี้เข้ามาด้วย **`parentId`**

```abap
  @UI.facet: [
    { id: 'GeneralTab', purpose: #STANDARD, type: #COLLECTION,
      label: 'General Information', position: 10 },

    { id: 'GeneralInfo', parentId: 'GeneralTab', purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'General Information', position: 10 },

    { id: 'Schedule', parentId: 'GeneralTab', purpose: #STANDARD,
      type: #FIELDGROUP_REFERENCE,
      label: 'Schedule', position: 20, targetQualifier: 'Schedule' },

    { id: 'AdminData', parentId: 'GeneralTab', purpose: #STANDARD,
      type: #FIELDGROUP_REFERENCE,
      label: 'Administrative Data', position: 30, targetQualifier: 'AdminData' },

    { id: 'OwnerFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Owners', position: 20, targetElement: '_Owner' },

    { id: 'ObjectFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Technical Objects', position: 30, targetElement: '_Object' },

    { id: 'TransportFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Transports', position: 40, targetElement: '_Transport' }
  ]
```

ตัวที่ไม่มี `parentId` ยังเป็น tab ระดับบนเหมือนเดิม → tab เหลือ 4 อัน

Fiori จะจัด 3 section เรียงเป็นคอลัมน์แนวนอนเมื่อจอกว้าง และซ้อนแนวตั้งเมื่อจอแคบ —
responsive behavior ปกติ ไม่ต้องแก้

### 5.4 `Remark` เป็นช่องหลายบรรทัด

```abap
  @UI.multiLineText: true
  @UI.fieldGroup: [{ qualifier: 'Schedule', position: 30 }]
  Remark;
```

### 5.5 ลำดับเริ่มต้นของ List Report

เดิมเรียงตาม UUID (สุ่ม) — เพิ่มในบล็อก header ของ MDE (ที่เดียวกับ `headerInfo`):

```abap
@UI.presentationVariant: [{ sortOrder: [{ by: 'RicefwID', direction: #ASC }] }]
```

### 5.6 ⚠️ `validateRicefwId` ไม่ทำงานตอน update — ช่องโหว่ที่เจอตอนคุยเรื่องแก้ ID

ตอน Phase 5.3 เขียนไว้ว่า:

```abap
validation validateRicefwId on save { create; field RicefwID; }   ← มีแค่ create
validation validateDates    on save { create; update; ... }
validation validateProgress on save { create; update; ... }
```

ตัวเดียวในสามที่ไม่มี `update;` เพราะตอนนั้นสมมติว่า RICEFW ID ตั้งครั้งเดียวแล้วจบ

**ผลถ้าปล่อยไว้** (ในเมื่อตัดสินใจให้ `RicefwID` แก้ได้หลังสร้าง เผื่อ user พิมพ์ผิด):
แก้ ID ไปชนกับ record อื่น → validation ไม่ทำงาน → ทะลุไปชน unique index `YRICEFW_HDR~Y01`
ที่ระดับ database → ได้ SQL error ดิบๆ แทนข้อความ *"RICEFW ID already exists"*

**แก้ด้วยการเติมคำเดียว** ไม่ต้องแตะ behavior pool:

```abap
validation validateRicefwId on save { create; update; field RicefwID; }
```

โค้ดใน handler รองรับอยู่แล้ว — `SELECT ... WHERE ricefw_uuid <> @lt_check-RicefwUUID`
เงื่อนไข `<>` ทำให้ตอน update ไม่ฟ้องว่าซ้ำกับตัวเอง

### 5.7 ⭐ Child validation ต้องผูกเข้า `Prepare` ด้วย `<alias>~<validation>`

warning ค้าง: *"Validation `validateProgress` is not assigned to any determine action
(not even Prepare)"*

`draft determine action Prepare` ประกาศได้เฉพาะที่ **root** แต่อ้างถึง validation ของ **child**
ได้ผ่าน `<child alias>~<ชื่อ validation>`:

```abap
  draft determine action Prepare
  {
    validation validateRicefwId;          " root — ไม่ต้องใส่ prefix
    validation validateDates;             " root
    validation Owner~validateProgress;    " child — ใส่ alias นำหน้า
  }
```

**ผลที่ได้มากกว่าการปิด warning**: `validateProgress` ทำงาน real-time ตอน user พิมพ์เลขใน
ตาราง Owners ระหว่างแก้ draft (ยืนยันจากการทดสอบจริง — error เด้งทันทีในหน้า Owner Details
ไม่ต้องรอกด Create)

> ⚠️ phase5_spec.md §5.4 เคยบันทึกผิดว่า warning นี้ "หายไปเองหลัง implement method" — ไม่จริง
> ตอนนี้แก้เอกสารนั้นแล้ว บทเรียน: **warning ที่ "หายเอง" โดยไม่ได้แก้อะไรตรงจุดนั้น ให้สงสัยไว้ก่อน**

### 5.8 Warning ที่เหลือไว้โดยตั้งใจ

```
Operation "create" should be equipped with (global) authorization.
```

bdef มี `authorization master ( instance )` ซึ่งคุมสิทธิ์**รายตัว** แต่ `create` ไม่มี record
ให้เช็ค ต้องใช้ **global authorization** ซึ่งเป็นคนละกลไก และต้องตัดสินใจเรื่อง authorization
object จริงก่อน = เนื้อหาของ Phase 9

**จงใจปล่อย warning ไว้** เพราะ stub ว่างๆ ที่อนุญาตทุกคนอันตรายกว่า warning ที่เตือนอยู่ตลอด
ว่ายังไม่ได้ทำ

---

## 6. ผลทดสอบ validation บน UI จริง

ทดสอบครบ 4 ข้อ ผ่านหมด — ยืนยันว่า validation ที่เขียนไว้ตั้งแต่ Phase 5 (และพิสูจน์ผ่าน EML
ใน smoke test) ทำงานบน UI จริงด้วย

| # | ทดสอบ | ผล |
|---|---|---|
| 1 | กด Create โดยไม่กรอกอะไร | ✅ *"RICEFW ID must not be initial"* + message popover ลิงก์ไปที่ field |
| 2 | Planned Finish ก่อน Planned Start | ✅ *"Plan finish date must not be before plan start date"* — เด้งทันทีระหว่างแก้ draft |
| 3 | Owner Progress = 150 | ✅ *"Progress must not exceed 100"* — **เด้งทันทีในหน้า Owner Details** (ผลของ 5.7) |
| 4 | RICEFW ID ซ้ำ | ✅ *"RICEFW ID already exists"* |

ข้อ 2 และ 3 เด้งแบบ real-time ระหว่างแก้ draft = ผลของการผูก validation เข้า
`draft determine action Prepare` ครบทุกตัว

---

## 7. Checklist

- [x] `YUI_RICEFW` Service Definition — expose 4 projection + 7 value help
- [x] alias ไม่ชนกับ property (`RicefwOwner`/`RicefwObject`/`RicefwTransport`)
- [x] `YUI_RICEFW_O4` Service Binding — OData V4 - UI
- [x] Activate + **Publish** — `$metadata` ตอบเป็น XML
- [x] Preview ผ่าน — List Report + Object Page แสดงครบ
- [x] Value help ทำงาน + เรียงถูก + ไม่มีคอลัมน์เกิน
- [x] Label ครบทุก field
- [x] Facet รวมเป็น 4 tab
- [x] ทดสอบ validation 4 ข้อบน UI — ผ่านหมด
- [ ] Phase 9 — authorization (warning `create` global auth ค้างไว้โดยตั้งใจ)

**Phase 8 จบแล้ว ✅ — แอปใช้งานได้จริงตั้งแต่ต้นจนจบ**
