@EndUserText.label: 'RICEFW Object - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_OBJECT
  as projection on YI_RICEFW_OBJECT
{
  key ObjectUUID,
      RicefwUUID,

      ObjectName,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_OTYP_VH', element: 'ObjectType' } }]
      @ObjectModel.text.element: [ 'ObjectTypeText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "In Development" #TEXT_FIRST = "In Development (DEV)"
      ObjectType,

      @Semantics.text: true
      _ObjectTypeVH.Description as ObjectTypeText,

      Description,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
