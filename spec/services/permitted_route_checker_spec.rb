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
end
