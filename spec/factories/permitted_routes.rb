FactoryBot.define do
  factory :permitted_route do
    carrier { 'S7' }
    origin_iata { 'UUS' }
    destination_iata { 'DME' }
    direct { true }
    transfer_iata_codes { [] }

    trait :with_transfer do
      direct { false }
      transfer_iata_codes { ['OVB'] }
    end

    trait :with_multiple_transfers do
      direct { false }
      transfer_iata_codes { ['OVB', 'KHV', 'IKT'] }
    end

    trait :with_compound_transfer do
      direct { false }
      transfer_iata_codes { ['VVOOVB'] }
    end

    trait :to_noz do
      destination_iata { 'NOZ' }
    end
  end
end
