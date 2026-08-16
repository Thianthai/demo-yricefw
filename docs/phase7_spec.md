# Phase 7 — Metadata Extensions (UI) ✅

Package: `YRICEFW` · 4 Metadata Extensions + แก้ view เดิมเพื่อดึง text/criticality — activate ผ่านครบ

---

## 1. ทำไมแยก MDE ไม่ใส่ UI annotation ใน projection view ตรงๆ

ใส่ใน projection view ก็ได้ แต่แยกดีกว่าเพราะ:

1. **UI annotation เยอะมาก** — ปนกับ field list แล้วอ่านโครงสร้างข้อมูลไม่ออก
2. **แก้หน้าจอไม่ต้องแตะ view** — เปลี่ยนลำดับคอลัมน์/ซ่อน field ทำที่ MDE ไฟล์เดียว
3. **`@Metadata.layer`** — ซ้อนได้หลายชั้น (`#CORE` → `#CUSTOMER`) ลูกค้าปรับ UI ทับได้โดยไม่แก้ของเรา

> ⚠️ **Prerequisite**: projection view ต้องมี `@Metadata.allowExtensions: true` (ใส่ไว้แล้วตั้งแต่
> Phase 6) ไม่งั้น MDE activate ไม่ผ่าน

## 2. โครงของ Phase 7 — 3 ขั้น

| ขั้น | เนื้อหา |
|---|---|
| 7.1 | MDE `YC_RICEFW` — List Report + Object Page + 6 facets |
| 7.2 | MDE ของ 3 child — ตารางในแต่ละ facet + progress bar |
| 7.3 | Text arrangement + criticality — **ต้องแตะ view ไม่ใช่แค่ MDE** |

---

## 3. `YC_RICEFW` MDE

สร้างจาก: คลิกขวาที่ `YC_RICEFW` → **New Metadata Extension** (ชื่อเดียวกับ view)

```abap
@Metadata.layer: #CORE

@UI: {
  headerInfo: {
    typeName:       'RICEFW Item',
    typeNamePlural: 'RICEFW Items',
    title:       { type: #STANDARD, value: 'RicefwID' },
    description: { type: #STANDARD, value: 'Description' }
  }
}
annotate entity YC_RICEFW with
{
  @UI.facet: [
    { id: 'GeneralInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
      label: 'General Information', position: 10 },

    { id: 'Schedule', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
      label: 'Schedule', position: 20, targetQualifier: 'Schedule' },

    { id: 'OwnerFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Owners', position: 30, targetElement: '_Owner' },

    { id: 'ObjectFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Technical Objects', position: 40, targetElement: '_Object' },

    { id: 'TransportFacet', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Transports', position: 50, targetElement: '_Transport' },

    { id: 'AdminData', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
      label: 'Administrative Data', position: 60, targetQualifier: 'AdminData' }
  ]

  @UI.hidden: true
  RicefwUUID;

  @UI: { lineItem:       [{ position: 10, importance: #HIGH }],
         identification: [{ position: 10 }],
         selectionField: [{ position: 10 }] }
  RicefwID;

  @UI: { lineItem:       [{ position: 20, importance: #HIGH }],
         identification: [{ position: 20 }],
         selectionField: [{ position: 20 }] }
  RicefwType;

  @UI: { lineItem:       [{ position: 30, importance: #MEDIUM }],
         identification: [{ position: 30 }],
         selectionField: [{ position: 30 }] }
  DeliveryType;

  @UI: { lineItem:       [{ position: 40, importance: #HIGH }],
         identification: [{ position: 40 }] }
  Description;

  @UI: { lineItem:       [{ position: 50, importance: #HIGH, criticality: 'OverallStatusCriticality' }],
         identification: [{ position: 50, criticality: 'OverallStatusCriticality' }],
         selectionField: [{ position: 40 }] }
  OverallStatus;

  @UI: { lineItem:   [{ position: 60, importance: #MEDIUM }],
         fieldGroup: [{ qualifier: 'Schedule', position: 10 }] }
  PlanStart;

  @UI: { lineItem:   [{ position: 70, importance: #MEDIUM }],
         fieldGroup: [{ qualifier: 'Schedule', position: 20 }] }
  PlanFinish;

  @UI.fieldGroup: [{ qualifier: 'Schedule', position: 30 }]
  Remark;

  @UI.fieldGroup: [{ qualifier: 'AdminData', position: 10 }]
  CreatedBy;

  @UI.fieldGroup: [{ qualifier: 'AdminData', position: 20 }]
  CreatedAt;

  @UI.fieldGroup: [{ qualifier: 'AdminData', position: 30 }]
  LastChangedBy;

  @UI.hidden: true
  LastChangedAt;

  @UI.hidden: true
  LocalLastChangedAt;

  /* --- ของที่เพิ่มใน 7.3 --- */
  @UI.hidden: true
  OverallStatusText;

  @UI.hidden: true
  OverallStatusCriticality;

  @UI.hidden: true
  RicefwTypeText;

  @UI.hidden: true
  DeliveryTypeText;
}
```

### annotation ไปโผล่ตรงไหนบนหน้าจอ

| Annotation | ผลบนหน้าจอ |
|---|---|
| `headerInfo.typeName` / `typeNamePlural` | ชื่อที่ Fiori เรียก object นี้ — "RICEFW Items (24)" บนหัว List Report, "Create RICEFW Item" บนปุ่ม |
| `headerInfo.title` / `description` | บรรทัดหัวของ Object Page — ผลของ `@ObjectModel.semanticKey` ที่ใส่ไว้ตอน Phase 6 |
| `@UI.facet` | ส่วน/แท็บใน Object Page — เรียงตาม `position` |
| `@UI.lineItem` | คอลัมน์ใน List Report |
| `@UI.identification` | field ในส่วนที่ facet เป็น `#IDENTIFICATION_REFERENCE` |
| `@UI.selectionField` | ช่องกรองบน filter bar ด้านบน List Report |
| `@UI.fieldGroup` | จับ field เป็นกลุ่ม ผูกกับ facet ผ่าน `targetQualifier` ที่ชื่อตรงกัน |
| `@UI.hidden` | ซ่อนสนิท — UUID, ETag timestamp, field ข้อความ/criticality ที่ดึงมาใช้ภายใน |

### 3 concept ที่ต้องจับให้ได้

**`importance`** (`#HIGH`/`#MEDIUM`/`#LOW`) — ไม่ใช่แค่ตกแต่ง แต่บอก Fiori ว่าจอแคบ (มือถือ)
ให้ยุบคอลัมน์ไหนก่อน `#HIGH` อยู่รอดถึงจอเล็กสุด

**`targetQualifier` ต้องตรงกับ `qualifier` เป๊ะ** — facet ที่เขียน `targetQualifier: 'Schedule'`
ไปหยิบทุก field ที่มี `fieldGroup: [{ qualifier: 'Schedule' }]` มาแสดง **พิมพ์ไม่ตรงกัน facet จะว่าง
โดยไม่มี error เตือน**

**`targetElement: '_Owner'`** — ชี้ไปที่ **association** ไม่ใช่ field ทำให้ Fiori รู้ว่าต้องดึง child
มาแสดงเป็นตาราง ส่วนหน้าตาของตารางนั้นนิยามใน MDE ของ child เอง

---

## 4. MDE ของ 3 child

แต่ละตัวทำ 2 หน้าที่พร้อมกัน: `lineItem` = คอลัมน์ของตารางที่ไปโผล่ใน facet ของ parent ·
`identification` + `facet` = หน้า detail ของตัวเองตอน user คลิกเข้าไปในแถว

### 4.1 `YC_RICEFW_OWNER` — มี progress bar

```abap
@Metadata.layer: #CORE

@UI: {
  headerInfo: {
    typeName:       'Owner',
    typeNamePlural: 'Owners',
    title:       { type: #STANDARD, value: 'OwnerName' },
    description: { type: #STANDARD, value: 'Role' }
  }
}
annotate entity YC_RICEFW_OWNER with
{
  @UI.facet: [
    { id: 'OwnerDetail', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
      label: 'Owner Details', position: 10 }
  ]

  @UI.hidden: true
  OwnerUUID;

  @UI.hidden: true
  RicefwUUID;

  @UI: { lineItem: [{ position: 10, importance: #HIGH }], identification: [{ position: 10 }] }
  OwnerID;

  @UI: { lineItem: [{ position: 20, importance: #HIGH }], identification: [{ position: 20 }] }
  OwnerName;

  @UI: { lineItem: [{ position: 30, importance: #HIGH }], identification: [{ position: 30 }] }
  Role;

  @UI.dataPoint: { title: 'Progress', visualization: #PROGRESS, targetValue: 100 }
  @UI: { lineItem:       [{ position: 40, importance: #MEDIUM, type: #AS_DATAPOINT }],
         identification: [{ position: 40, type: #AS_DATAPOINT }] }
  Progress;

  @UI.hidden: true
  CreatedBy;

  @UI.hidden: true
  CreatedAt;

  @UI.hidden: true
  LastChangedBy;

  @UI.hidden: true
  LocalLastChangedAt;

  @UI.hidden: true
  RoleText;
}
```

**`@UI.dataPoint` + `type: #AS_DATAPOINT`** — คู่นี้ทำให้ `Progress` แสดงเป็น **แถบ progress bar**
แทนตัวเลขเปล่า · `targetValue: 100` บอกว่าเต็มสเกลคือ 100 ตรงกับ `validateProgress` (Phase 5.4)
ที่กัน > 100 ไว้

### 4.2 `YC_RICEFW_OBJECT`

โครงเดียวกับ owner — `ObjectName` (10) `ObjectType` (20) `Description` (30) ·
`headerInfo` ใช้ `ObjectName` เป็น title, `ObjectType` เป็น description ·
ซ่อน `ObjectUUID` `RicefwUUID` admin field ทั้ง 4 และ `ObjectTypeText`

### 4.3 `YC_RICEFW_TRANSPORT` — มี criticality

`TransportType` (10) `TransportID` (20) `Description` (30) `TransportStatus` (40)
`ImportSequence` (50, `#LOW`) `ReleasedOn` (60)

```abap
  @UI: { lineItem:       [{ position: 40, importance: #HIGH, criticality: 'TransportStatusCriticality' }],
         identification: [{ position: 40, criticality: 'TransportStatusCriticality' }] }
  TransportStatus;
```

ซ่อน `TransportUUID` `RicefwUUID` admin field ทั้ง 4 · `TransportTypeText`
`TransportStatusText` `TransportStatusCriticality`

### หมายเหตุการออกแบบของ child

**ซ่อน admin field ทั้งหมด** — ต่างจาก root ที่มี facet "Administrative Data" เพราะตารางย่อยที่มี
คอลัมน์ created/changed จะกว้างจนคอลัมน์สำคัญโดนบีบ

**`RicefwUUID` ซ่อนทุกตัว** — เป็น FK ที่ RAP เติมเองผ่าน composition (`field ( readonly )` ใน bdef)
user ไม่ต้องเห็นและแก้ไม่ได้อยู่แล้ว

**`ImportSequence` เป็น `#LOW`** — ข้อมูลเชิงเทคนิคที่ดูเฉพาะตอนไล่ปัญหาลำดับ import จอแคบยุบทิ้งได้ก่อน

---

## 5. ⭐ 7.3 — Text arrangement + Criticality (ขั้นที่ต้องแตะ view)

### ปัญหา

`OverallStatus` ในตารางเก็บแค่ `'DEV'` ส่วน `"In Development"` และ `criticality = 0` อยู่ใน
`YRICEFW_STAT_VH` คนละที่กัน — ต้องต่อสะพาน (association) ให้ RAP เดินไปหยิบมาได้

```
YRICEFW_HDR.overall_status = 'DEV'
        │
        └─ association ──→ YI_RICEFW_STAT_VH
                              ├─ Description = 'In Development'   → แสดงแทน code
                              └─ Criticality = 0                  → ระบายสี
```

### ทำไม association ต้องอยู่ที่ interface view ไม่ใช่ projection

projection view **redirect/expose association ที่มีอยู่แล้วได้ แต่นิยาม association ใหม่ไปหา
entity อื่นไม่ได้** — ต้องมีต้นทางที่ชั้นล่างก่อน

### ⚠️ ห้ามเอา text/criticality ขึ้นเป็น element ที่ interface view

ที่ interface view ให้ **expose แค่ตัว association** พอ — ถ้าเอา `_StatusVH.Description` ขึ้นมาเป็น
element ที่ชั้นนี้ด้วย จะเจอ warning เดิมจาก Phase 5.1:

```
Field "OVERALLSTATUSTEXT" of entity "YR_RICEFW" does not have a mapping to table "YRICEFW_HDR"
```

เพราะ managed persistence จะพยายามหา column ที่ไม่มีจริงในตาราง — **path element ต้องอยู่ที่ชั้น
projection เท่านั้น** ซึ่งไม่ใช่ persistence layer จึงไม่มีปัญหานี้

### 💡 ยืนยันแล้ว: projection view เขียน path expression ได้

ก่อนลงมือยังไม่แน่ใจว่า projection view จะยอมให้เขียน `_StatusVH.Description as OverallStatusText`
ในรายการ element หรือไม่ (เตรียมแผนสำรองไว้ 2 ทาง: ย้ายไป interface view + `field ( readonly )`
ใน bdef, หรือ virtual element ผ่าน ABAP class) — **ผลคือทางตรงใช้ได้เลย ไม่ต้องใช้แผนสำรอง**

### Pattern ที่ใช้ซ้ำได้ทุก field (ตัวอย่าง `OverallStatus`)

**ขั้น A — interface view `YR_RICEFW`**

```abap
  association [0..1] to YI_RICEFW_STAT_VH as _StatusVH
    on $projection.OverallStatus = _StatusVH.OverallStatus
```

expose ท้าย element list:
```abap
      _Owner,
      _Object,
      _Transport,

      _StatusVH
}
```

**ขั้น B — projection view `YC_RICEFW`**

```abap
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_STAT_VH', element: 'OverallStatus' } }]
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      @UI.textArrangement: #TEXT_FIRST //#TEXT_ONLY = "Description Text" #TEXT_FIRST = "Description Text (Key)"
      OverallStatus,

      @Semantics.text: true
      _StatusVH.Description as OverallStatusText,

      _StatusVH.Criticality as OverallStatusCriticality,
```

| Annotation | หน้าที่ |
|---|---|
| `@ObjectModel.text.element` | ผูก field code เข้ากับ field ข้อความ — บอก OData ว่าสองตัวนี้เป็นคู่กัน |
| `@UI.textArrangement` | รูปแบบการแสดงผล — `#TEXT_ONLY` = ข้อความอย่างเดียว · `#TEXT_FIRST` = ข้อความ + code ในวงเล็บ (ดู §5.1 ว่าแต่ละ field เลือกแบบไหน) |
| `@Semantics.text: true` | ยืนยันว่า field นี้เป็นข้อความของ code — ควรไหลมาจาก VH view เองอยู่แล้ว แต่ระบุซ้ำกันเหนียว |

⚠️ **annotation ทั้ง 3 ตัวไม่ได้เกาะ element เดียวกัน** — `@ObjectModel.text.element` กับ
`@UI.textArrangement` เกาะที่ **field code** (`OverallStatus`) ส่วน `@Semantics.text: true`
เกาะที่ **field ข้อความ** (`OverallStatusText`) · เวลาอ่าน git diff จะดูเหมือนกองรวมกัน
เพราะบรรทัด field code ไม่ได้เปลี่ยนเลยไม่โผล่ใน diff — ต้องเปิดไฟล์เต็มถึงจะเห็นตำแหน่งจริง

### 5.1 ตาราง `@UI.textArrangement` ของทุก field (ฉบับที่ยึดเป็นมาตรฐาน)

| # | View | Field | Arrangement | ผลบนหน้าจอ |
|---|---|---|---|---|
| 1 | `YC_RICEFW` | `RicefwType` | `#TEXT_ONLY` | Report |
| 2 | `YC_RICEFW` | `DeliveryType` | `#TEXT_ONLY` | New Development |
| 3 | `YC_RICEFW` | `OverallStatus` | **`#TEXT_FIRST`** | In Development (DEV) |
| 4 | `YC_RICEFW_OWNER` | `Role` | `#TEXT_ONLY` | ABAP Developer |
| 5 | `YC_RICEFW_OBJECT` | `ObjectType` | **`#TEXT_FIRST`** | Behavior Definition (BDEF) |
| 6 | `YC_RICEFW_TRANSPORT` | `TransportType` | `#TEXT_ONLY` | Workbench Request |
| 7 | `YC_RICEFW_TRANSPORT` | `TransportStatus` | `#TEXT_ONLY` | Modifiable |

**`#TEXT_ONLY` 5 จุด · `#TEXT_FIRST` 2 จุด**

### หลักที่ใช้เลือก — `#TEXT_ONLY` เป็น default

**ใช้ `#TEXT_ONLY` เป็นค่าตั้งต้นเสมอ** แล้วเปลี่ยนเป็น `#TEXT_FIRST` เฉพาะ field ที่
**คนใช้พูดกันด้วยตัว code จริงๆ ในชีวิตประจำวัน**

- `OverallStatus` — ทีมคุยกันว่า *"อันนี้ยัง DEV อยู่"* / *"ขึ้น UAT รึยัง"* ไม่มีใครพูดว่า
  "อยู่ในขั้น User Testing"
- `ObjectType` — เป็น code มาตรฐานของ SAP ที่ developer จำได้ขึ้นใจ (`CLAS` `BDEF` `DDLS` `TABL`)
  แถม description ยาวมาก (`API Release State of Objects`) ไม่มี code ห้อยจะหาของยากกว่า

อีก 5 ตัวเป็น code ที่ตั้งเองในโปรเจกต์ ไม่มีใครจำ `INTF` หรือ `LS` — เห็นข้อความอย่างเดียวชัดกว่า

**ขั้น C — MDE**

```abap
  @UI: { lineItem:       [{ position: 50, importance: #HIGH, criticality: 'OverallStatusCriticality' }],
         identification: [{ position: 50, criticality: 'OverallStatusCriticality' }],
         selectionField: [{ position: 40 }] }
  OverallStatus;

  @UI.hidden: true
  OverallStatusText;

  @UI.hidden: true
  OverallStatusCriticality;
```

**ต้องซ่อนทั้งคู่** — `OverallStatusText` ถูกดึงไปแสดงแทน code ผ่าน text arrangement อยู่แล้ว
ไม่ซ่อนจะกลายเป็นคอลัมน์ซ้ำ · `OverallStatusCriticality` เป็นเลข 0–3 ที่ไม่มีความหมายกับ user

### ตารางสรุป association ทั้ง 7 ตัวที่เพิ่ม

| Interface view | Association | ชี้ไป | ได้อะไรกลับมา |
|---|---|---|---|
| `YR_RICEFW` | `_StatusVH` | `YI_RICEFW_STAT_VH` | Description + **Criticality** |
| `YR_RICEFW` | `_TypeVH` | `YI_RICEFW_TYPE_VH` | Description |
| `YR_RICEFW` | `_DeliveryTypeVH` | `YI_RICEFW_DTYP_VH` | Description |
| `YI_RICEFW_OWNER` | `_RoleVH` | `YI_RICEFW_ROLE_VH` | Description |
| `YI_RICEFW_OBJECT` | `_ObjectTypeVH` | `YI_RICEFW_OTYP_VH` | Description |
| `YI_RICEFW_TRANSPORT` | `_TransportTypeVH` | `YI_RICEFW_TTYP_VH` | Description |
| `YI_RICEFW_TRANSPORT` | `_TransportStatusVH` | `YI_RICEFW_TRST_VH` | Description + **Criticality** |

### ลำดับ activate ที่ใช้จริง

ทำ **ทีละ field** ตามลำดับ interface → projection → MDE เริ่มจาก `OverallStatus` ตัวเดียวก่อน
เพื่อทดสอบว่า pattern ใช้ได้ แล้วค่อยขยายไปอีก 6 field ที่เหลือ — วิธีนี้ทำให้ถ้าพังจะรู้ทันทีว่า
พังเพราะอะไร (บทเรียนจาก phase5_spec.md เรื่องแก้ทีละจุด)

### ผลลัพธ์ที่ได้

| Status | เดิม | หลัง 7.3 |
|---|---|---|
| `OPN` / `HLD` | `OPN` | 🟡 Not Assigned / On Hold |
| `DEV` `UT` `FAT` `SIT` `UAT` `PND` | `DEV` | ⬜ In Development ฯลฯ |
| `CLS` | `CLS` | 🟢 Done |
| `CAN` | `CAN` | 🔴 Cancelled |
| `ERR` (transport) | `ERR` | 🔴 Import Error |

criticality ที่ออกแบบไว้ตั้งแต่ Phase 3 (§6.3, §6.7) ได้ใช้จริงตรงนี้ — **สีสื่อว่า "ต้องจัดการไหม"
ไม่ใช่ "อยู่ขั้นไหน"** จึงเห็นสีเหลืองที่ `OPN`/`HLD` ซึ่งเป็นงานค้างที่ต้องมีคนไปแตะ

---

## 6. Checklist

- [x] **7.1** MDE `YC_RICEFW` — headerInfo + 6 facets + lineItem/identification/selectionField/fieldGroup
- [x] **7.2** MDE `YC_RICEFW_OWNER` — table facet + **progress bar** (`@UI.dataPoint` + `#AS_DATAPOINT`)
- [x] **7.2** MDE `YC_RICEFW_OBJECT` — table facet
- [x] **7.2** MDE `YC_RICEFW_TRANSPORT` — table facet + criticality บน `TransportStatus`
- [x] **7.3** เพิ่ม association 7 ตัวใน interface view ทั้ง 4
- [x] **7.3** เพิ่ม path element (text + criticality) ใน projection view ทั้ง 4
- [x] **7.3** ผูก `criticality:` ใน MDE + ซ่อน field ที่ดึงมาใช้ภายใน
- [x] activate ผ่านครบทุกไฟล์

**Phase 7 จบแล้ว ✅ — ต่อไป Phase 8 จะได้เห็นหน้าจอจริงครั้งแรก**
