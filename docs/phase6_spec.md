# Phase 6 — Projection Views & Behavior Projection ✅

Package: `YRICEFW` · 4 CDS projection views + 1 behavior projection — activate ผ่านครบ

---

## 1. ทำไมต้องมีชั้น projection

| ชั้น | Object | หน้าที่ |
|---|---|---|
| Interface (Phase 4) | `YR_RICEFW`, `YI_RICEFW_*` | "ข้อมูลดิบ" — field ครบทุกตัว ไม่ผูกกับ UI ใด ใช้ซ้ำได้จากหลาย consumer |
| Projection (Phase 6) | `YC_RICEFW`, `YC_RICEFW_*` | "หน้าร้าน" ของ UI ตัวนี้ — เลือก field, ผูก value help, เปิดทางให้ MDE |

แยกชั้นเพื่อไม่ให้ interface view เปื้อน annotation ของ UI ตัวใดตัวหนึ่ง — วันหลังทำ UI ตัวที่ 2
(เช่น analytical) สร้าง projection ใหม่บน interface view เดิมได้เลย ไม่ต้องแตะของเก่า

## 2. Header annotation — ต่างจาก interface view 1 บรรทัดสำคัญ

```abap
@EndUserText.label: '...'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
```

### ⚠️ `@Metadata.ignorePropagatedAnnotations` — ต้อง**ลบ**ที่ชั้น projection

ADT template ของ projection view ใส่ `@Metadata.ignorePropagatedAnnotations: true` มาให้เป็น
default — **ลบทิ้ง** แล้วใช้ `@Metadata.allowExtensions: true` แทน

annotation นี้แปลว่า "ตัดทุก annotation ที่ไหลมาจาก data source ข้างล่าง" ซึ่งต้องการคนละแบบกัน
ในสองชั้น:

| ชั้น | source ข้างล่างคือ | อยากให้ annotation ไหลมาไหม |
|---|---|---|
| Interface view (Phase 4) | table + `I_User` (view ของ SAP ที่เราไม่ได้คุม) | **ไม่** — กันของแปลกจาก `I_User` → ตั้ง `true` |
| Projection view (Phase 6) | interface view **ของเราเอง** | **ใช่** — เราใส่ annotation พวกนั้นเองกับมือ |

ถ้าปิด propagate ที่ projection จะเสียของที่อุตส่าห์ใส่ไว้ที่ interface view:
`@Semantics.user.createdBy`, `@Semantics.systemDateTime.*`, `@Semantics.text` จะไม่ไหลขึ้นถึง
OData → Fiori ไม่รู้ว่า field ไหนเป็น created-by/timestamp · และ label ของ field ที่ไหลมาทาง
data element ก็อาจหายไปด้วย ต้องมานั่งใส่ `@EndUserText.label` เองทุก field

**`@Metadata.allowExtensions: true` ต้องมีทุกตัว** — เป็นประตูให้ Metadata Extension ของ
Phase 7 เข้ามาแปะ UI annotation ได้ ไม่ใส่ตอนนี้ Phase 7 จะ activate ไม่ผ่านแล้วต้องย้อนมาแก้

## 3. Syntax ใหม่ 3 ตัว

| Syntax | หน้าที่ |
|---|---|
| `as projection on <interface view>` | แทน `as select from <table>` — สืบทอดโครงสร้างมาทั้งชุด ไม่ต้องเขียน join ใหม่ |
| `redirected to composition child` / `redirected to parent` | **บังคับ** — บอกว่า association ที่สืบทอดมาให้ชี้ไป projection ตัวไหน ไม่งั้นจะชี้กลับไปที่ interface view ซึ่ง UI เข้าไม่ถึง |
| `provider contract transactional_query` | ประกาศว่า view นี้เป็นหน้าร้านของ RAP transactional BO (ไม่ใช่ analytical/value help) — ใส่ที่ root เท่านั้น |

⚠️ **Circular dependency เหมือน Phase 4 เป๊ะ** — root อ้าง child ผ่าน `redirected to composition
child`, child อ้าง root ผ่าน `redirected to parent` → เขียนครบทั้ง 4 ไฟล์ (save เฉยๆ) แล้ว
**mass-activate พร้อมกัน**

---

## 4. `YC_RICEFW` — Root Projection View

```abap
@EndUserText.label: 'RICEFW Master - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'RicefwID' ]
define root view entity YC_RICEFW
  provider contract transactional_query
  as projection on YR_RICEFW
{
  key RicefwUUID,

      @Search.defaultSearchElement: true
      RicefwID,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_TYPE_VH', element: 'RicefwType' } }]
      RicefwType,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_DTYP_VH', element: 'DeliveryType' } }]
      DeliveryType,

      @Search.defaultSearchElement: true
      Description,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_STAT_VH', element: 'OverallStatus' } }]
      OverallStatus,

      PlanStart,
      PlanFinish,
      Remark,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Owner     : redirected to composition child YC_RICEFW_OWNER,
      _Object    : redirected to composition child YC_RICEFW_OBJECT,
      _Transport : redirected to composition child YC_RICEFW_TRANSPORT
}
```

**`@ObjectModel.semanticKey: [ 'RicefwID' ]`** — ทำให้ Fiori แสดง `RicefwID` เป็นตัวระบุ record
แทน UUID ที่อ่านไม่รู้เรื่อง (เห็นผลจริงตอน Phase 7–8)

## 5. `YC_RICEFW_OWNER`

```abap
@EndUserText.label: 'RICEFW Owner - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_OWNER
  as projection on YI_RICEFW_OWNER
{
  key OwnerUUID,
      RicefwUUID,

      OwnerID,
      OwnerName,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_ROLE_VH', element: 'Role' } }]
      Role,

      Progress,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
```

## 6. `YC_RICEFW_OBJECT`

```abap
@EndUserText.label: 'RICEFW Object - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_OBJECT
  as projection on YI_RICEFW_OBJECT
{
  key ObjectUUID,
      RicefwUUID,

      ObjectName,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_OTYP_VH', element: 'ObjectType' } }]
      ObjectType,

      Description,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
```

## 7. `YC_RICEFW_TRANSPORT`

```abap
@EndUserText.label: 'RICEFW Transport - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_TRANSPORT
  as projection on YI_RICEFW_TRANSPORT
{
  key TransportUUID,
      RicefwUUID,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_TTYP_VH', element: 'TransportType' } }]
      TransportType,

      TransportID,
      Description,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_TRST_VH', element: 'TransportStatus' } }]
      TransportStatus,

      ImportSequence,
      ReleasedOn,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
```

## 8. Value help mapping — ผูกครบ 7 ตัวจาก Phase 3

| Projection view | Field | Value help view | Element |
|---|---|---|---|
| `YC_RICEFW` | `RicefwType` | `YI_RICEFW_TYPE_VH` | `RicefwType` |
| `YC_RICEFW` | `DeliveryType` | `YI_RICEFW_DTYP_VH` | `DeliveryType` |
| `YC_RICEFW` | `OverallStatus` | `YI_RICEFW_STAT_VH` | `OverallStatus` |
| `YC_RICEFW_OWNER` | `Role` | `YI_RICEFW_ROLE_VH` | `Role` |
| `YC_RICEFW_OBJECT` | `ObjectType` | `YI_RICEFW_OTYP_VH` | `ObjectType` |
| `YC_RICEFW_TRANSPORT` | `TransportType` | `YI_RICEFW_TTYP_VH` | `TransportType` |
| `YC_RICEFW_TRANSPORT` | `TransportStatus` | `YI_RICEFW_TRST_VH` | `TransportStatus` |

`OwnerID` / `OwnerName` ไม่มี value help ตามที่ตกลงไว้ (design.md ข้อ 5) — owner อาจเป็น external
consultant ที่ไม่มี user ในระบบ จึงให้กรอกเอง

---

## 9. Behavior Projection `YC_RICEFW`

สร้างจาก: คลิกขวาที่ `YC_RICEFW` (projection view) → **New Behavior Definition** — ADT รู้เองว่า
base view มี bdef อยู่แล้ว จึง pre-fill template แบบ `projection;` ให้

> 💡 **ADT generate ออกมาตรงกับที่ร่างไว้ทุกบรรทัด ไม่ต้องแก้อะไรเลย** — ต่างจาก EML ที่ syntax
> เดาไม่ได้ (ดู phase5_spec.md §5.7) เพราะ behavior projection derive ได้ทั้งหมดจาก base bdef
> ไม่มีอะไรให้ตัดสินใจเอง

### แนวคิด: ไม่ได้ "นิยาม" อะไรใหม่ แค่ "เปิดประตู"

Base bdef (Phase 5) นิยามทุกอย่างไว้หมดแล้ว — table mapping, `field ( mandatory )`,
determination, validation, lock, ETag · behavior projection มีหน้าที่เดียวคือบอกว่าจะเปิดอะไร
ให้ UI ตัวนี้ใช้บ้าง ผ่าน keyword `use`

**validation/determination ไม่ต้องประกาศซ้ำ และประกาศไม่ได้ด้วย** — รันอัตโนมัติที่ชั้น base
ทุกครั้งที่มีการเขียนข้อมูล ไม่ว่ามาจาก UI, EML หรือ OData (smoke test พิสูจน์แล้วว่ารันจริง
ตอน `COMMIT ENTITIES`)

```abap
projection;
strict ( 2 );
use draft;

define behavior for YC_RICEFW alias RicefwMaster
{
  use create;
  use update;
  use delete;

  use action Activate;
  use action Discard;
  use action Edit;
  use action Resume;
  use action Prepare;

  use association _Owner { create; with draft; }
  use association _Object { create; with draft; }
  use association _Transport { create; with draft; }
}

define behavior for YC_RICEFW_OBJECT alias Object
{
  use update;
  use delete;

  use association _RicefwMaster { with draft; }
}

define behavior for YC_RICEFW_OWNER alias Owner
{
  use update;
  use delete;

  use association _RicefwMaster { with draft; }
}

define behavior for YC_RICEFW_TRANSPORT alias Transport
{
  use update;
  use delete;

  use association _RicefwMaster { with draft; }
}
```

> 💡 ADT เรียง `use action` และ `define behavior` block ของ child **ตามตัวอักษร** ให้เอง
> (Activate/Discard/Edit/Resume/Prepare · OBJECT/OWNER/TRANSPORT) ไม่ใช่ตามลำดับที่ร่างไว้ —
> ลำดับไม่มีผลต่อการทำงาน แต่ยึดตามที่ ADT generate ไว้จะได้ไม่มี diff เวลา push ซ้ำ

### เทียบกับ base bdef

| Base bdef (`YR_RICEFW`) | Behavior projection (`YC_RICEFW`) |
|---|---|
| `managed implementation in class ybp_r_ricefw unique;` | `projection;` |
| `with draft;` | **`use draft;`** |
| `persistent table` / `draft table` / `mapping for` | ไม่มี — สืบทอดทั้งหมด |
| `field ( mandatory )` / `field ( readonly )` | ไม่มี — สืบทอดทั้งหมด |
| `create; update; delete;` | **`use create; use update; use delete;`** |
| `draft action Activate optimized;` | **`use action Activate;`** (ไม่ต้องใส่ `optimized` ซ้ำ) |
| `determination` / `validation` | ไม่มี — รันเองที่ชั้น base |
| `association _Owner { create; with draft; }` | **`use association _Owner { create; with draft; }`** |

### จุดที่ต้องระวัง

**`alias` ต้องตั้งชื่อเดิม** (`RicefwMaster`/`Owner`/`Object`/`Transport`) — alias จะกลายเป็นชื่อ
**entity set ใน OData** ตอน Phase 8 ถ้าเปลี่ยนตรงนี้ URL และ annotation ที่อ้างถึงจะเพี้ยนตามหมด

**child ไม่มี `use create;`** — ตรงกับ base bdef ที่ child สร้างได้ผ่าน composition association
เท่านั้น (`use association _Owner { create; }` ที่ root คือประตูนั้น)

**`use action Prepare;` ห้ามลืม** — `strict ( 2 )` บังคับให้ประกาศ draft action ครบทั้ง 5 ตัว
ขาดตัวไหน activate ไม่ผ่าน

---

## 10. Checklist

- [x] `YC_RICEFW` — root projection + `provider contract transactional_query` + semantic key
- [x] `YC_RICEFW_OWNER` — projection + `redirected to parent`
- [x] `YC_RICEFW_OBJECT` — projection + `redirected to parent`
- [x] `YC_RICEFW_TRANSPORT` — projection + `redirected to parent`
- [x] Mass-activate ทั้ง 4 ไฟล์พร้อมกัน — ผ่านหมด
- [x] `@Metadata.allowExtensions: true` ครบทุกตัว (เตรียมทางให้ Phase 7)
- [x] `@Metadata.ignorePropagatedAnnotations` ลบออกจาก template แล้วทุกตัว
- [x] Value help ผูกครบ 7 จุด
- [x] Behavior projection `YC_RICEFW` — `projection; strict(2); use draft;` activate ผ่าน

**Phase 6 จบแล้ว ✅**
