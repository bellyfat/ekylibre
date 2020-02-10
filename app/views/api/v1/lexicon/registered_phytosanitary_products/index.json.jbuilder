json.set! :data do
  json.array! @updated do |phytosanitary_product|
    json.call(phytosanitary_product, :id,
                                  :reference_name,
                                  :name,
                                  :other_name,
                                  :nature,
                                  :active_compounds,
                                  :france_maaid,
                                  :mix_category_code,
                                  :in_field_reentry_delay,
                                  :state,
                                  :started_on,
                                  :stopped_on,
                                  :allowed_mentions,
                                  :restricted_mentions,
                                  :operator_protection_mentions,
                                  :firm_name,
                                  :product_type,
                                  :record_checksum)
  end

  json.array! @removed do |removed|
    json.call(removed, "id")
  end
end
