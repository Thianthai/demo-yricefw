@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RICEFW Master - Root View Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity YR_RICEFW
  as select from yricefw_hdr

  composition [0..*] of YI_RICEFW_OWNER     as _Owner
  composition [0..*] of YI_RICEFW_OBJECT    as _Object
  composition [0..*] of YI_RICEFW_TRANSPORT as _Transport

  association [0..1] to YI_RICEFW_STAT_VH as _StatusVH
    on $projection.OverallStatus = _StatusVH.OverallStatus
    
  association [0..1] to YI_RICEFW_TYPE_VH as _TypeVH
    on $projection.RicefwType = _TypeVH.RicefwType

  association [0..1] to YI_RICEFW_DTYP_VH as _DeliveryTypeVH
    on $projection.DeliveryType = _DeliveryTypeVH.DeliveryType
{
  key ricefw_uuid           as RicefwUUID,

      ricefw_id             as RicefwID,
      ricefw_type           as RicefwType,
      delivery_type         as DeliveryType,
      description           as Description,
      overall_status        as OverallStatus,
      plan_start            as PlanStart,
      plan_finish           as PlanFinish,
      remark                as Remark,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /* composition children */
      _Owner,
      _Object,
      _Transport,
      
      /* เผื่อ upgrade ภายหลัง — ประกาศ association ไว้ แต่ยังไม่ expose field จาก association */
      _StatusVH,
      _TypeVH,
      _DeliveryTypeVH
}
