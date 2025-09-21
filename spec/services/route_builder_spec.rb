require 'rails_helper'

RSpec.describe RouteBuilder do
  let(:segment1) { create(:segment, origin_iata: 'UUS', destination_iata: 'OVB', std: Time.zone.parse('2024-01-01 10:00:00'), sta: Time.zone.parse('2024-01-01 12:00:00')) }
  let(:segment2) { create(:segment, origin_iata: 'OVB', destination_iata: 'DME', std: Time.zone.parse('2024-01-01 20:00:00'), sta: Time.zone.parse('2024-01-01 22:00:00')) }
  let(:segment3) { create(:segment, origin_iata: 'DME', destination_iata: 'SVO', std: Time.zone.parse('2024-01-02 06:00:00'), sta: Time.zone.parse('2024-01-02 08:00:00')) }

  describe '#build' do
    context 'with valid connection times' do
      let(:segment_candidates) { [[segment1], [segment2]] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'builds valid routes' do
        routes = builder.build
        expect(routes).to be_an(Array)
        expect(routes.length).to eq(1)
        expect(routes.first).to eq([segment1, segment2])
      end
    end

    context 'with invalid connection times' do
      let(:invalid_segment2) { create(:segment, origin_iata: 'OVB', destination_iata: 'DME', std: Time.zone.parse('2024-01-01 13:00:00'), sta: Time.zone.parse('2024-01-01 15:00:00')) } # 1 hour connection - too short
      let(:segment_candidates) { [[segment1], [invalid_segment2]] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'filters out invalid connections' do
        routes = builder.build
        expect(routes).to be_empty
      end
    end

    context 'with empty candidates' do
      let(:segment_candidates) { [] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'returns empty array' do
        expect(builder.build).to eq([])
      end
    end

    context 'with nil candidates' do
      let(:segment_candidates) { nil }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'returns empty array' do
        expect(builder.build).to eq([])
      end
    end

    context 'with empty leg candidates' do
      let(:segment_candidates) { [[segment1], []] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'returns empty array' do
        expect(builder.build).to eq([])
      end
    end

    context 'with multiple valid routes' do
      let(:segment1_alt) { create(:segment, origin_iata: 'UUS', destination_iata: 'OVB', std: Time.zone.parse('2024-01-01 11:00:00'), sta: Time.zone.parse('2024-01-01 13:00:00')) }
      let(:segment2_alt) { create(:segment, origin_iata: 'OVB', destination_iata: 'DME', std: Time.zone.parse('2024-01-01 21:00:00'), sta: Time.zone.parse('2024-01-01 23:00:00')) } # 8 hours after segment1_alt
      let(:segment_candidates) { [[segment1, segment1_alt], [segment2, segment2_alt]] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'builds all valid combinations' do
        routes = builder.build
        expect(routes.length).to eq(3) # Only 3 valid combinations due to connection time constraints
        expect(routes).to include([segment1, segment2], [segment1, segment2_alt], [segment1_alt, segment2_alt])
      end
    end

    context 'with three-leg route' do
      let(:segment_candidates) { [[segment1], [segment2], [segment3]] }
      let(:builder) { described_class.new(segment_candidates: segment_candidates) }

      it 'builds valid three-leg routes' do
        routes = builder.build
        expect(routes).to be_an(Array)
        expect(routes.length).to eq(1)
        expect(routes.first).to eq([segment1, segment2, segment3])
      end
    end
  end
end
