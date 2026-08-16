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
      @ObjectModel.text.element: [ 'RicefwTypeText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "In Development" #TEXT_FIRST = "In Development (DEV)"
      RicefwType,

      @Semantics.text: true
      _TypeVH.Description as RicefwTypeText,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_DTYP_VH', element: 'DeliveryType' } }]
      @ObjectModel.text.element: [ 'DeliveryTypeText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "In Development" #TEXT_FIRST = "In Development (DEV)"
      DeliveryType,

      @Semantics.text: true
      _DeliveryTypeVH.Description as DeliveryTypeText,

      @Search.defaultSearchElement: true
      Description,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_STAT_VH', element: 'OverallStatus' } }]
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      @UI.textArrangement: #TEXT_FIRST //#TEXT_ONLY = "In Development" #TEXT_FIRST = "In Development (DEV)"
      OverallStatus,

      @Semantics.text: true
      _StatusVH.Description as OverallStatusText,

      _StatusVH.Criticality as OverallStatusCriticality,
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
