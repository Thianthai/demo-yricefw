@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RICEFW Master - Root View Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity YR_RICEFW
  as select from yricefw_hdr

  composition [0..*] of YI_RICEFW_OWNER     as _Owner
  composition [0..*] of YI_RICEFW_OBJECT    as _Object
  composition [0..*] of YI_RICEFW_TRANSPORT as _Transport
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
      _Transport
}
