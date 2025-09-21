require 'rails_helper'

RSpec.describe SegmentFinder do
  let(:carrier) { 'S7' }
  let(:departure_from) { Time.zone.parse('2024-01-01 00:00:00') }
  let(:departure_to) { Time.zone.parse('2024-01-07 23:59:59') }
  let(:finder) { described_class.new(carrier: carrier, departure_from: departure_from, departure_to: departure_to) }

  describe '#initialize' do
    it 'sets the carrier and time range' do
      expect(finder.instance_variable_get(:@carrier)).to eq(carrier)
      expect(finder.instance_variable_get(:@from)).to eq(departure_from.beginning_of_day.utc)
      expect(finder.instance_variable_get(:@to)).to eq(departure_to.end_of_day.utc)
    end
  end

  describe '#find_direct_segments' do
    let!(:segment) { create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-02 10:00:00')) }
    let!(:other_carrier_segment) { create(:segment, airline: 'SU', origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-02 10:00:00')) }
    let!(:out_of_range_segment) { create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-10 10:00:00')) }

    it 'returns segments for the specified route' do
      segments = finder.find_direct_segments(origin_iata: 'UUS', destination_iata: 'DME')
      expect(segments).to include(segment)
    end

    it 'filters by carrier' do
      segments = finder.find_direct_segments(origin_iata: 'UUS', destination_iata: 'DME')
      expect(segments).not_to include(other_carrier_segment)
    end

    it 'filters by time range' do
      segments = finder.find_direct_segments(origin_iata: 'UUS', destination_iata: 'DME')
      expect(segments).not_to include(out_of_range_segment)
    end

    it 'orders segments by departure time' do
      Segment.destroy_all # Clear existing segments
      segment1 = create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-03 10:00:00'))
      segment2 = create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-01 10:00:00'))
      
      segments = finder.find_direct_segments(origin_iata: 'UUS', destination_iata: 'DME')
      expect(segments.map(&:std)).to eq([segment2.std, segment1.std])
    end
  end

  describe '#find_segments_for_route' do
    let!(:segment) { create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'DME', std: Time.zone.parse('2024-01-02 10:00:00')) }

    it 'returns segments with extended time window' do
      segments = finder.find_segments_for_route(origin_iata: 'UUS', destination_iata: 'DME')
      expect(segments).to include(segment)
    end
  end

  describe '#find_segments_for_legs' do
    let!(:segment1) { create(:segment, airline: carrier, origin_iata: 'UUS', destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 10:00:00')) }
    let!(:segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: 'DME', std: Time.zone.parse('2024-01-02 15:00:00')) }
    let(:legs) { [['UUS', 'OVB'], ['OVB', 'DME']] }

    it 'returns segments grouped by leg' do
      segments_by_leg = finder.find_segments_for_legs(legs)
      expect(segments_by_leg[['UUS', 'OVB']]).to include(segment1)
      expect(segments_by_leg[['OVB', 'DME']]).to include(segment2)
    end
  end

  describe '#parse_transfer_codes' do
    it 'returns single code as array' do
      expect(finder.parse_transfer_codes('OVB')).to eq(['OVB'])
    end

    it 'splits compound codes' do
      expect(finder.parse_transfer_codes('VVOOVB')).to eq(['VVO', 'OVB'])
    end

    it 'handles empty string' do
      expect(finder.parse_transfer_codes('')).to eq([])
    end

    it 'handles nil' do
      expect(finder.parse_transfer_codes(nil)).to eq([])
    end
  end

  describe '#build_route_legs' do
    it 'builds legs for single transfer' do
      legs = finder.build_route_legs('UUS', ['OVB'], 'DME')
      expect(legs).to eq([['UUS', 'OVB'], ['OVB', 'DME']])
    end

    it 'builds legs for multiple transfers' do
      legs = finder.build_route_legs('UUS', ['OVB', 'KHV'], 'DME')
      expect(legs).to eq([['UUS', 'OVB'], ['OVB', 'KHV'], ['KHV', 'DME']])
    end

    it 'handles compound transfer codes' do
      legs = finder.build_route_legs('UUS', ['VVOOVB'], 'DME')
      expect(legs).to eq([['UUS', 'VVO'], ['VVO', 'OVB'], ['OVB', 'DME']])
    end
  end
end
