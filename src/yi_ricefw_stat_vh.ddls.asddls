@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Overall Status - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
@UI.presentationVariant: [{ sortOrder: [{ by: 'SortOrder', direction: #ASC }] }]
define view entity YI_RICEFW_STAT_VH
  as select from yricefw_stat_vh as Status
  inner join yricefw_stat_vht as Text on  Text.overall_status = Status.overall_status
                                      and Text.spras          = $session.system_language
{
  key Status.overall_status as OverallStatus,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description      as Description,

      @UI.hidden: true
      Status.sort_order     as SortOrder,
      
      @UI.hidden: true
      Status.criticality    as Criticality
}
where
  Status.is_active = 'X'
