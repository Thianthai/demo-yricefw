@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RICEFW Transport - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity YI_RICEFW_TRANSPORT
  as select from yricefw_trsp

  association to parent YR_RICEFW as _RicefwMaster
    on $projection.RicefwUUID = _RicefwMaster.RicefwUUID
    
  association [0..1] to YI_RICEFW_TTYP_VH as _TransportTypeVH
    on $projection.TransportType = _TransportTypeVH.TransportType

  association [0..1] to YI_RICEFW_TRST_VH as _TransportStatusVH
    on $projection.TransportStatus = _TransportStatusVH.TransportStatus
{
  key transport_uuid        as TransportUUID,
      ricefw_uuid           as RicefwUUID,

      transport_type        as TransportType,
      transport_id          as TransportID,
      description           as Description,
      transport_status      as TransportStatus,
      import_sequence       as ImportSequence,
      released_on           as ReleasedOn,

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
      
      /* เผื่อ upgrade ภายหลัง — ประกาศ association ไว้ แต่ยังไม่ expose field จาก association */
      _TransportTypeVH,
      _TransportStatusVH
}
