require 'rails_helper'

RSpec.describe PermittedRouteChecker do
  let(:carrier) { 'S7' }
  let(:origin_iata) { 'UUS' }
  let(:destination_iata) { 'DME' }
  let(:checker) { described_class.new(carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }

  describe '#initialize' do
    it 'sets the carrier, origin, and destination' do
      expect(checker.instance_variable_get(:@carrier)).to eq(carrier)
      expect(checker.instance_variable_get(:@origin)).to eq(origin_iata)
      expect(checker.instance_variable_get(:@destination)).to eq(destination_iata)
    end
  end

  describe '#routes' do
    let!(:permitted_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }

    it 'returns permitted routes for the given trip' do
      routes = checker.routes
      expect(routes).to include(permitted_route)
    end

    it 'memoizes the result' do
      expect(checker.routes).to eq(checker.routes)
    end

    it 'does not return routes for different carriers' do
      create(:permitted_route, carrier: 'SU', origin_iata: origin_iata, destination_iata: destination_iata)
      routes = checker.routes
      expect(routes.map(&:carrier)).to all(eq('S7'))
    end

    it 'does not return routes for different origins' do
      create(:permitted_route, carrier: carrier, origin_iata: 'SVO', destination_iata: destination_iata)
      routes = checker.routes
      expect(routes.map(&:origin_iata)).to all(eq('UUS'))
    end

    it 'does not return routes for different destinations' do
      create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: 'SVO')
      routes = checker.routes
      expect(routes.map(&:destination_iata)).to all(eq('DME'))
    end
  end

  describe '#direct_routes_allowed?' do
    context 'when direct routes are allowed' do
      before { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true) }

      it 'returns true' do
        expect(checker.direct_routes_allowed?).to be true
      end
    end

    context 'when no direct routes are allowed' do
      before { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: false) }

      it 'returns false' do
        expect(checker.direct_routes_allowed?).to be false
      end
    end

    context 'when no routes exist' do
      it 'returns false' do
        expect(checker.direct_routes_allowed?).to be false
      end
    end
  end

  describe '#transfer_routes' do
    let!(:direct_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true) }
    let!(:transfer_route) { create(:permitted_route, :with_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }

    it 'returns transfer codes from transfer routes only' do
      transfer_codes = checker.transfer_routes
      expect(transfer_codes).to include('OVB')
    end

    it 'does not include direct routes' do
      transfer_codes = checker.transfer_routes
      expect(transfer_codes).not_to include([])
    end
  end

  describe '#all_transfer_codes' do
    let!(:direct_route) { create(:permitted_route, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata, direct: true) }
    let!(:transfer_route) { create(:permitted_route, :with_transfer, carrier: carrier, origin_iata: origin_iata, destination_iata: destination_iata) }

    it 'returns transfer codes from all routes' do
      all_codes = checker.all_transfer_codes
      expect(all_codes).to include('OVB')
    end
  end

  describe '#transfer_codes' do
    let(:scope) { double('scope') }
    let(:transfer_codes) { [['OVB'], ['KHV']] }

    before do
      allow(scope).to receive(:pluck).with(:transfer_iata_codes).and_return(transfer_codes)
    end

    it 'flattens and compacts the transfer codes' do
      result = checker.transfer_codes(scope)
      expect(result).to eq(['OVB', 'KHV'])
    end
  end
end
