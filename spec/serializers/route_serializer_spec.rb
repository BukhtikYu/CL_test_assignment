require 'rails_helper'

RSpec.describe RouteSerializer do
  let(:segment1) { create(:segment, origin_iata: 'UUS', destination_iata: 'OVB', std: Time.zone.parse('2024-01-01 10:00:00'), sta: Time.zone.parse('2024-01-01 12:00:00')) }
  let(:segment2) { create(:segment, origin_iata: 'OVB', destination_iata: 'DME', std: Time.zone.parse('2024-01-01 15:00:00'), sta: Time.zone.parse('2024-01-01 17:00:00')) }
  let(:segments) { [segment1, segment2] }
  let(:serializer) { described_class.new(segments) }

  describe '#as_json' do
    let(:result) { serializer.as_json }

    it 'returns a hash with correct structure' do
      expect(result).to be_a(Hash)
      expect(result.keys).to match_array(['origin_iata', 'destination_iata', 'departure_time', 'arrival_time', 'segments'])
    end

    it 'sets origin_iata from first segment' do
      expect(result['origin_iata']).to eq('UUS')
    end

    it 'sets destination_iata from last segment' do
      expect(result['destination_iata']).to eq('DME')
    end

    it 'sets departure_time from first segment' do
      expect(result['departure_time']).to eq('2024-01-01T10:00:00Z')
    end

    it 'sets arrival_time from last segment' do
      expect(result['arrival_time']).to eq('2024-01-01T17:00:00Z')
    end

    it 'includes segments array' do
      expect(result['segments']).to be_an(Array)
      expect(result['segments'].length).to eq(2)
    end

    it 'serializes each segment correctly' do
      segment_data = result['segments'].first
      expect(segment_data).to include(
        'carrier' => segment1.airline,
        'segment_number' => segment1.segment_number,
        'origin_iata' => segment1.origin_iata,
        'destination_iata' => segment1.destination_iata,
        'std' => '2024-01-01T10:00:00Z',
        'sta' => '2024-01-01T12:00:00Z'
      )
    end

    context 'with single segment' do
      let(:segments) { [segment1] }

      it 'works with single segment' do
        expect(result['origin_iata']).to eq('UUS')
        expect(result['destination_iata']).to eq('OVB')
        expect(result['segments'].length).to eq(1)
      end
    end

    context 'with nil times' do
      let(:segment_with_nil_times) { create(:segment, std: nil, sta: nil) }
      let(:segments) { [segment_with_nil_times] }

      it 'handles nil times gracefully' do
        result = described_class.new(segments).as_json
        expect(result['departure_time']).to be_nil
        expect(result['arrival_time']).to be_nil
        expect(result['segments'].first['std']).to be_nil
        expect(result['segments'].first['sta']).to be_nil
      end
    end
  end

  describe '#serialize_segment' do
    it 'serializes a segment correctly' do
      segment_data = serializer.send(:serialize_segment, segment1)
      expect(segment_data).to eq({
        'carrier' => segment1.airline,
        'segment_number' => segment1.segment_number,
        'origin_iata' => segment1.origin_iata,
        'destination_iata' => segment1.destination_iata,
        'std' => '2024-01-01T10:00:00Z',
        'sta' => '2024-01-01T12:00:00Z'
      })
    end
  end
end
