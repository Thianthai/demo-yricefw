# Phase 4 — CDS Data Model (Interface + Root) ✅

Package: `YRICEFW` · 4 CDS view entities (1 root + 3 child) — activate ผ่านครบ (mass-activate)

---

## 1. โครงสร้าง

```
YR_RICEFW (root)
├── _Owner     : composition [0..*] → YI_RICEFW_OWNER
├── _Object    : composition [0..*] → YI_RICEFW_OBJECT
└── _Transport : composition [0..*] → YI_RICEFW_TRANSPORT
```

## 2. ⚠️ Circular dependency — ต้อง mass-activate

Root ต้องมี child อยู่ก่อน (`composition of` อ้างถึง type ที่ต้อง exist) แต่ child ก็ต้องมี root
อยู่ก่อน (`association to parent` อ้างถึง type ที่ต้อง exist) — ทั้ง 4 ไฟล์อ้างอิงกันเป็นวง

**ทางแก้**: เขียนทั้ง 4 ไฟล์ให้เสร็จก่อน (save เฉยๆ ไม่ activate ทีละไฟล์) แล้ว select ทั้ง 4 ไฟล์ใน
Project Explorer พร้อมกัน แล้ว activate เป็น batch เดียว — ADT resolve dependency graph ให้เอง

## 3. Naming convention — DB field `snake_case` → CDS element `UpperCamelCase`

ยึดมาจาก Phase 3 ตาม pattern ของ ABAP Flight Reference Scenario — ตัวย่อ (`ID`, `UUID`) เขียน
พิมพ์ใหญ่ทั้งหมด (`OwnerID`, `TransportUUID`, `RicefwID`) ใช้กับทุก view ตั้งแต่นี้ไป

## 4. Header annotations ที่ใช้กับทุกไฟล์

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: '...'
```

| Annotation | หน้าที่ | ทำไมใส่ |
|---|---|---|
| `@AccessControl.authorizationCheck: #NOT_REQUIRED` | ปิด auth check | ชั่วคราว — รัดให้แน่นตอน Phase 9 |
| `@AbapCatalog.viewEnhancementCategory: [#NONE]` | ห้าม partner/customer เพิ่ม field เข้า view ผ่าน `extend view entity` | เป็น internal view ของ `Y` namespace เอง ไม่มีใครมา extend |
| `@Metadata.ignorePropagatedAnnotations: true` | ตัด annotation ที่ไหลมาจาก underlying source (table/CDS อื่น) | กันไม่ให้ annotation ของ `I_User` (ที่ `_User` association ชี้ไป) ไหลเข้ามาสวมทับโดยไม่ตั้งใจ |

> ทั้งสอง annotation **ไม่บังคับต้องมีถึงจะ activate ได้** — 7 CDS value help view ใน Phase 3
> activate ผ่านโดยไม่มี annotation นี้เลย (source เป็น table ธรรมดา ไม่มีอะไรให้ propagate)
> แต่เป็น best practice ที่ควรใส่เป็นนิสัย โดยเฉพาะพอเริ่มมี view ที่ select จาก CDS entity อื่น

---

## 5. `YI_RICEFW_OWNER`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'RICEFW Owner - Interface View'
define view entity YI_RICEFW_OWNER
  as select from yricefw_owner

  association to parent YR_RICEFW as _RicefwMaster
    on $projection.RicefwUUID = _RicefwMaster.RicefwUUID

  association [0..1] to I_User as _User
    on $projection.OwnerID = _User.UserID
{
  key owner_uuid             as OwnerUUID,
      ricefw_uuid             as RicefwUUID,

      owner_id                as OwnerID,
      owner_name               as OwnerName,
      role                     as Role,
      progress                 as Progress,

      @Semantics.user.createdBy: true
      created_by               as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by           as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at      as LocalLastChangedAt,

      /* composition parent — ใช้โดย RAP สำหรับ lock/ETag/root determination */
      _RicefwMaster,

      /* เผื่อ upgrade ภายหลัง — ยังไม่ expose field จาก I_User */
      _User
}
```

## 6. `YI_RICEFW_OBJECT`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'RICEFW Object - Interface View'
define view entity YI_RICEFW_OBJECT
  as select from yricefw_obj

  association to parent YR_RICEFW as _RicefwMaster
    on $projection.RicefwUUID = _RicefwMaster.RicefwUUID
{
  key object_uuid            as ObjectUUID,
      ricefw_uuid             as RicefwUUID,

      object_name              as ObjectName,
      object_type              as ObjectType,
      description               as Description,

      @Semantics.user.createdBy: true
      created_by                as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by            as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at       as LocalLastChangedAt,

      _RicefwMaster
}
```

## 7. `YI_RICEFW_TRANSPORT`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'RICEFW Transport - Interface View'
define view entity YI_RICEFW_TRANSPORT
  as select from yricefw_trsp

  association to parent YR_RICEFW as _RicefwMaster
    on $projection.RicefwUUID = _RicefwMaster.RicefwUUID
{
  key transport_uuid          as TransportUUID,
      ricefw_uuid              as RicefwUUID,

      transport_type            as TransportType,
      transport_id               as TransportID,
      description                 as Description,
      transport_status            as TransportStatus,
      import_sequence              as ImportSequence,
      released_on                  as ReleasedOn,

      @Semantics.user.createdBy: true
      created_by                    as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                     as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at           as LocalLastChangedAt,

      _RicefwMaster
}
```

## 8. `YR_RICEFW` — Root View Entity

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'RICEFW Master - Root View Entity'
define root view entity YR_RICEFW
  as select from yricefw_hdr

  composition [0..*] of YI_RICEFW_OWNER     as _Owner
  composition [0..*] of YI_RICEFW_OBJECT    as _Object
  composition [0..*] of YI_RICEFW_TRANSPORT as _Transport
{
  key ricefw_uuid              as RicefwUUID,

      ricefw_id                 as RicefwID,
      ricefw_type                as RicefwType,
      delivery_type               as DeliveryType,
      description                  as Description,
      overall_status                as OverallStatus,
      plan_start                     as PlanStart,
      plan_finish                     as PlanFinish,
      remark                           as Remark,

      @Semantics.user.createdBy: true
      created_by                        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                         as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                     as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                      as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                 as LocalLastChangedAt,

      _Owner,
      _Object,
      _Transport
}
```

---

## 9. บทเรียนที่เจอ (บันทึกลง memory แล้ว)

**`define root view entity`** — keyword `root` บอก RAP ว่า entity นี้เป็นรากของ composition tree
ต่างจาก child ที่ใช้ `define view entity` เฉยๆ

**`association to parent`** — keyword พิเศษเฉพาะสำหรับ composition child (ต่างจาก
`association [n..n] to ... as ...` ธรรมดา) ใช้บอก RAP ว่า entity นี้เป็น child ของ root ที่ระบุ
ผ่าน field ไหน — RAP ใช้ข้อมูลนี้ทำ lock propagation, ETag rollup, root determination อัตโนมัติ

**Composition ที่ root ไม่ต้องมี `on` condition** — ถ้า child ประกาศ `association to parent`
ไว้แล้ว composition ฝั่ง root จะจับคู่ ON condition จาก association นั้นให้อัตโนมัติ ไม่ต้องเขียนซ้ำ

**ETag 2 ระดับ ต่างกันที่ semantics annotation**

| Field | Semantics annotation | อยู่ที่ |
|---|---|---|
| `local_last_changed_at` | `@Semantics.systemDateTime.localInstanceLastChangedAt` | ทุก entity (root + child) |
| `last_changed_at` | `@Semantics.systemDateTime.lastChangedAt` | root เท่านั้น — total ETag ของทั้ง tree |

## 10. Checklist

- [x] `YI_RICEFW_OWNER`
- [x] `YI_RICEFW_OBJECT`
- [x] `YI_RICEFW_TRANSPORT`
- [x] `YR_RICEFW`
- [x] Mass-activate ทั้ง 4 ไฟล์พร้อมกัน — ผ่านหมด

**Phase 4 จบแล้ว ✅**
