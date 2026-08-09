@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Role - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity YI_RICEFW_ROLE_VH
  as select from yricefw_role_vh as Role
  inner join yricefw_role_vht as Text on  Text.role  = Role.role
                                      and Text.spras = $session.system_language
{
  key Role.role        as Role,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description as Description,

      Role.sort_order  as SortOrder
}
where
  Role.is_active = 'X'
