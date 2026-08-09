@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RICEFW Type - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity YI_RICEFW_TYPE_VH
  as select from yricefw_type_vh as Type 
  inner join yricefw_type_vht as Text on  Text.ricefw_type = Type.ricefw_type
                                      and Text.spras       = $session.system_language
{
  key Type.ricefw_type as RicefwType,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description as Description,

      Type.sort_order  as SortOrder
}
where
  Type.is_active = 'X'
