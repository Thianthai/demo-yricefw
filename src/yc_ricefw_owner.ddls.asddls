@EndUserText.label: 'RICEFW Owner - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_RICEFW_OWNER
  as projection on YI_RICEFW_OWNER
{
  key OwnerUUID,
      RicefwUUID,

      OwnerID,
      OwnerName,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_RICEFW_ROLE_VH', element: 'Role' } }]
      Role,

      Progress,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
