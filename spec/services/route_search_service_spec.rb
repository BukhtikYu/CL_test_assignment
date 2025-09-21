require 'rails_helper'

RSpec.describe RouteSearchService do
  let(:carrier) { 'S7' }
  let(:origin_iata) { 'UUS' }
  let(:destination_iata) { 'DME' }
  let(:departure_from) { Time.zone.parse('2024-01-01 00:00:00') }
  let(:departure_to) { Time.zone.parse('2024-01-07 23:59:59') }
  let(:service) { described_class.new(carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, departure_from: departure_from, departure_to: departure_to) }

  describe '#initialize' do
    it 'sets all required attributes' do
      expect(service.instance_variable_get(:@carrier)).to eq(carrier)
      expect(service.instance_variable_get(:@origin)).to eq(origin_iata)
      expect(service.instance_variable_get(:@destination)).to eq(destination_iata)
      expect(service.instance_variable_get(:@departure_from)).to eq(departure_from)
      expect(service.instance_variable_get(:@departure_to)).to eq(departure_to)
    end

    it 'initializes segment finder' do
      expect(service.instance_variable_get(:@segment_finder)).to be_a(SegmentFinder)
    end
  end

  describe '#call' do
    context 'with direct routes only' do
      let!(:permitted_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true) }
      let!(:segment) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 10:00:00')) }

      it 'returns direct routes' do
        results = service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)
        expect(results.first['origin_iata']).to eq(origin_iata)
        expect(results.first['destination_iata']).to eq(destination_iata)
        expect(results.first['segments'].length).to eq(1)
      end
    end

    context 'with transfer routes only' do
      let!(:permitted_route) { create(:permitted_route, :with_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }
      let!(:segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 10:00:00'), sta: Time.zone.parse('2024-01-02 12:00:00')) }
      let!(:segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 20:00:00'), sta: Time.zone.parse('2024-01-02 22:00:00')) } # 8 hours later

      it 'returns transfer routes' do
        results = service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)
        expect(results.first['origin_iata']).to eq(origin_iata)
        expect(results.first['destination_iata']).to eq(destination_iata)
        expect(results.first['segments'].length).to eq(2)
      end
    end

    context 'with both direct and transfer routes' do
      let!(:permitted_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true, transfer_iata_codes: ['OVB']) }
      let!(:direct_segment) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 10:00:00')) }
      let!(:transfer_segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 11:00:00'), sta: Time.zone.parse('2024-01-02 13:00:00')) }
      let!(:transfer_segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 21:00:00'), sta: Time.zone.parse('2024-01-02 23:00:00')) } # 8 hours later

      it 'returns both direct and transfer routes' do
        results = service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(2) # One direct, one transfer
        
        direct_route = results.find { |r| r['segments'].length == 1 }
        transfer_route = results.find { |r| r['segments'].length == 2 }
        
        expect(direct_route).to be_present
        expect(transfer_route).to be_present
      end
    end

    context 'with multiple transfer codes' do
      let!(:permitted_route) { create(:permitted_route, :with_multiple_transfers, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }
      let!(:ovb_segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 10:00:00'), sta: Time.zone.parse('2024-01-02 12:00:00')) }
      let!(:ovb_segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 20:00:00'), sta: Time.zone.parse('2024-01-02 22:00:00')) } # 8 hours later
      let!(:khv_segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'KHV', std: Time.zone.parse('2024-01-02 11:00:00'), sta: Time.zone.parse('2024-01-02 13:00:00')) }
      let!(:khv_segment2) { create(:segment, airline: carrier, origin_iata: 'KHV', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 21:00:00'), sta: Time.zone.parse('2024-01-02 23:00:00')) } # 8 hours later

      it 'returns routes for all transfer codes' do
        results = service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(2) # One for OVB, one for KHV
      end
    end

    context 'with compound transfer codes' do
      let!(:permitted_route) { create(:permitted_route, :with_compound_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }
      let!(:segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'VVO', std: Time.zone.parse('2024-01-02 10:00:00'), sta: Time.zone.parse('2024-01-02 12:00:00')) }
      let!(:segment2) { create(:segment, airline: carrier, origin_iata: 'VVO', destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 20:00:00'), sta: Time.zone.parse('2024-01-02 22:00:00')) } # 8 hours later
      let!(:segment3) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-03 06:00:00'), sta: Time.zone.parse('2024-01-03 08:00:00')) } # 8 hours later

      it 'handles compound transfer codes correctly' do
        results = service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)
        expect(results.first['segments'].length).to eq(3)
      end
    end

    context 'with no permitted routes' do
      it 'returns empty array' do
        results = service.call
        expect(results).to eq([])
      end
    end

    context 'with permitted routes but no segments' do
      let!(:permitted_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true) }

      it 'returns empty array' do
        results = service.call
        expect(results).to eq([])
      end
    end

    context 'with invalid connection times' do
      let!(:permitted_route) { create(:permitted_route, :with_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }
      let!(:segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 10:00:00'), sta: Time.zone.parse('2024-01-02 12:00:00')) }
      let!(:segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 12:30:00'), sta: Time.zone.parse('2024-01-02 14:30:00')) } # Too short connection

      it 'filters out invalid connections' do
        results = service.call
        expect(results).to eq([])
      end
    end
  end

  describe '#build_direct_routes' do
    let!(:segment) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 10:00:00')) }

    it 'returns serialized direct routes' do
      results = service.send(:build_direct_routes)
      expect(results).to be_an(Array)
      expect(results.length).to eq(1)
      expect(results.first).to include('origin_iata', 'destination_iata', 'departure_time', 'arrival_time', 'segments')
    end
  end

  describe '#build_transfer_routes' do
    let!(:permitted_route) { create(:permitted_route, :with_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }
    let!(:segment1) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: 'OVB', std: Time.zone.parse('2024-01-02 10:00:00'), sta: Time.zone.parse('2024-01-02 12:00:00')) }
    let!(:segment2) { create(:segment, airline: carrier, origin_iata: 'OVB', destination_iata: destination_iata, std: Time.zone.parse('2024-01-02 20:00:00'), sta: Time.zone.parse('2024-01-02 22:00:00')) } # 8 hours later

    it 'returns serialized transfer routes' do
      results = service.send(:build_transfer_routes, permitted_route)
      expect(results).to be_an(Array)
      expect(results.length).to eq(1)
      expect(results.first).to include('origin_iata', 'destination_iata', 'departure_time', 'arrival_time', 'segments')
      expect(results.first['segments'].length).to eq(2)
    end
  end

  describe 'UUS → NOZ route' do
    let(:noz_destination) { 'NOZ' }
    let(:noz_service) { described_class.new(carrier: carrier, origin_iata: origin_iata, destination_iata: noz_destination, departure_from: departure_from, departure_to: departure_to) }

    context 'with direct routes only' do
      let!(:permitted_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: noz_destination, direct: true) }
      let!(:segment) { create(:segment, airline: carrier, origin_iata: origin_iata, destination_iata: noz_destination, std: Time.zone.parse('2024-01-03 08:00:00')) }

      it 'returns direct routes for NOZ' do
        results = noz_service.call
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)
        expect(results.first['origin_iata']).to eq(origin_iata)
        expect(results.first['destination_iata']).to eq(noz_destination)
        expect(results.first['segments'].length).to eq(1)
      end
    end
  end
end
