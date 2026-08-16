@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transport Type - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
@UI.presentationVariant: [{ sortOrder: [{ by: 'SortOrder', direction: #ASC }] }]
define view entity YI_RICEFW_TTYP_VH
  as select from yricefw_ttyp_vh as TransportType
  inner join yricefw_ttyp_vht as Text on  Text.transport_type = TransportType.transport_type
                                      and Text.spras          = $session.system_language
{
  key TransportType.transport_type as TransportType,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description             as Description,

      @UI.hidden: true
      TransportType.sort_order     as SortOrder
}
where
  TransportType.is_active = 'X'
