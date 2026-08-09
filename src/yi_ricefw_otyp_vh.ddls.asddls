@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Object Type - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity YI_RICEFW_OTYP_VH
  as select from yricefw_otyp_vh as ObjType
  inner join yricefw_otyp_vht as Text on  Text.object_type = ObjType.object_type
                                      and Text.spras       = $session.system_language
{
  key ObjType.object_type as ObjectType,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description    as Description,

      ObjType.sort_order  as SortOrder
}
where
  ObjType.is_active = 'X'
