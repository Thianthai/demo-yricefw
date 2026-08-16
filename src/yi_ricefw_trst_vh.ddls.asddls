@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transport Status - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
@UI.presentationVariant: [{ sortOrder: [{ by: 'SortOrder', direction: #ASC }] }]
define view entity YI_RICEFW_TRST_VH
  as select from yricefw_trst_vh as TransportStatus
  inner join yricefw_trst_vht as Text on  Text.transport_status = TransportStatus.transport_status
                                      and Text.spras            = $session.system_language
{
  key TransportStatus.transport_status as TransportStatus,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description                 as Description,

      @UI.hidden: true
      TransportStatus.sort_order       as SortOrder,

      @UI.hidden: true
      TransportStatus.criticality      as Criticality
}
where
  TransportStatus.is_active = 'X'
