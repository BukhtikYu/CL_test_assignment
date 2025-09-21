FactoryBot.define do
  factory :segment do
    airline { 'S7' }
    sequence(:segment_number) { |n| "S7#{n.to_s.rjust(3, '0')}" }
    origin_iata { 'UUS' }
    destination_iata { 'DME' }
    std { Time.zone.parse('2024-01-02 10:00:00') }
    sta { Time.zone.parse('2024-01-02 14:00:00') }
  end

  factory :segment_with_transfer, parent: :segment do
    origin_iata { 'UUS' }
    destination_iata { 'OVB' }
    sta { Time.zone.parse('2024-01-02 12:00:00') }
  end

  factory :segment_ovb_to_dme, parent: :segment do
    origin_iata { 'OVB' }
    destination_iata { 'DME' }
    std { Time.zone.parse('2024-01-02 15:00:00') }
    sta { Time.zone.parse('2024-01-02 18:00:00') }
  end

  factory :segment_to_noz, parent: :segment do
    origin_iata { 'UUS' }
    destination_iata { 'NOZ' }
    std { Time.zone.parse('2024-01-03 08:00:00') }
    sta { Time.zone.parse('2024-01-03 12:00:00') }
  end
end
