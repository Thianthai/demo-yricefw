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
      @ObjectModel.text.element: [ 'RoleText' ]
      @UI.textArrangement: #TEXT_ONLY //#TEXT_ONLY = "In Development" #TEXT_FIRST = "In Development (DEV)"
      Role,

      @Semantics.text: true
      _RoleVH.Description as RoleText,

      Progress,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _RicefwMaster : redirected to parent YC_RICEFW
}
