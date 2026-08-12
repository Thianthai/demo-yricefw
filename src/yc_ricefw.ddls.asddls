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
