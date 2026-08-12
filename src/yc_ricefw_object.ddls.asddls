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
      ObjectType,

      Description,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
