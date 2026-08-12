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
