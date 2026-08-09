@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Delivery Type - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity YI_RICEFW_DTYP_VH
  as select from yricefw_dtyp_vh as DeliveryType
  inner join yricefw_dtyp_vht as Text on  Text.delivery_type = DeliveryType.delivery_type
                                      and Text.spras         = $session.system_language
{
  key DeliveryType.delivery_type as DeliveryType,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.description           as Description,

      DeliveryType.sort_order    as SortOrder
}
where
  DeliveryType.is_active = 'X'
