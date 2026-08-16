@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RICEFW Object - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity YI_RICEFW_OBJECT
  as select from yricefw_obj

  association to parent YR_RICEFW as _RicefwMaster
    on $projection.RicefwUUID = _RicefwMaster.RicefwUUID
    
  association [0..1] to YI_RICEFW_OTYP_VH as _ObjectTypeVH
    on $projection.ObjectType = _ObjectTypeVH.ObjectType
{
  key object_uuid           as ObjectUUID,
      ricefw_uuid           as RicefwUUID,

      object_name           as ObjectName,
      object_type           as ObjectType,
      description           as Description,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /* composition parent — ใช้โดย RAP สำหรับ lock/ETag/root determination */
      _RicefwMaster,
      
      /* value help — expose Description/Criticality ที่ชั้น projection (YC_*) */
      _ObjectTypeVH
}
