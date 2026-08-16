@EndUserText.label: 'RICEFW Transport - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_TRANSPORT
  as projection on YI_RICEFW_TRANSPORT
{
  key TransportUUID,
      RicefwUUID,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_TTYP_VH', element: 'TransportType' } }]
      @ObjectModel.text.element: [ 'TransportTypeText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "Description Text" #TEXT_FIRST = "Description Text (Key)"
      TransportType,

      @Semantics.text: true
      _TransportTypeVH.Description as TransportTypeText,

      TransportID,
      
      @EndUserText.label: 'Description'
      Description,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_TRST_VH', element: 'TransportStatus' } }]
      @ObjectModel.text.element: [ 'TransportStatusText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "Description Text" #TEXT_FIRST = "Description Text (Key)"
      TransportStatus,

      @Semantics.text: true
      _TransportStatusVH.Description as TransportStatusText,

      _TransportStatusVH.Criticality as TransportStatusCriticality,

      @EndUserText.label: 'Import Sequence'
      ImportSequence,
      
      @EndUserText.label: 'Released On'
      ReleasedOn,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
