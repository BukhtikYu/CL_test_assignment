require 'rails_helper'

RSpec.describe 'Routes API', type: :request do
  describe 'POST /routes/search' do
    let(:valid_params) do
      {
        carrier: 'S7',
        origin_iata: 'UUS',
        destination_iata: 'DME',
        departure_from: '2024-01-01',
        departure_to: '2024-01-07'
      }
    end

    before do
      # Create test data for UUS → DME route
      create(:permitted_route, carrier: 'S7', origin_iata: 'UUS', destination_iata: 'DME', direct: true)
      create(:segment, airline: 'S7', origin_iata: 'UUS', destination_iata: 'DME', 
             std: Time.zone.parse('2024-01-02 10:00:00'), 
             sta: Time.zone.parse('2024-01-02 14:00:00'))
      
      # Create test data for UUS → NOZ route
      create(:permitted_route, carrier: 'S7', origin_iata: 'UUS', destination_iata: 'NOZ', direct: true)
      create(:segment, airline: 'S7', origin_iata: 'UUS', destination_iata: 'NOZ', 
             std: Time.zone.parse('2024-01-03 08:00:00'), 
             sta: Time.zone.parse('2024-01-03 12:00:00'))
    end

    context 'with valid parameters' do
      it 'returns successful response' do
        post '/routes/search', params: valid_params, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
      end

      it 'returns array of routes' do
        post '/routes/search', params: valid_params, as: :json
        
        routes = JSON.parse(response.body)
        expect(routes).to be_an(Array)
        expect(routes.length).to eq(1)
      end

      it 'returns properly formatted route data' do
        post '/routes/search', params: valid_params, as: :json
        
        route = JSON.parse(response.body).first
        expect(route).to include(
          'origin_iata' => 'UUS',
          'destination_iata' => 'DME',
          'departure_time' => anything,
          'arrival_time' => anything,
          'segments' => anything
        )
        expect(route['segments']).to be_an(Array)
        expect(route['segments'].length).to eq(1)
      end

      it 'returns properly formatted segment data' do
        post '/routes/search', params: valid_params, as: :json
        
        segment = JSON.parse(response.body).first['segments'].first
        expect(segment).to include(
          'carrier' => 'S7',
          'segment_number' => anything,
          'origin_iata' => 'UUS',
          'destination_iata' => 'DME',
          'std' => anything,
          'sta' => anything
        )
      end
    end

    context 'with transfer routes' do
      before do
        create(:permitted_route, :with_transfer, carrier: 'S7', origin_iata: 'UUS', destination_iata: 'DME')
        create(:segment, airline: 'S7', origin_iata: 'UUS', destination_iata: 'OVB', 
               std: Time.zone.parse('2024-01-02 10:00:00'), 
               sta: Time.zone.parse('2024-01-02 12:00:00'))
        create(:segment, airline: 'S7', origin_iata: 'OVB', destination_iata: 'DME', 
               std: Time.zone.parse('2024-01-02 20:00:00'), 
               sta: Time.zone.parse('2024-01-02 22:00:00')) # 8 hours later
      end

      it 'returns transfer routes' do
        post '/routes/search', params: valid_params, as: :json
        
        routes = JSON.parse(response.body)
        expect(routes.length).to eq(2) # One direct, one transfer
        
        transfer_route = routes.find { |r| r['segments'].length == 2 }
        expect(transfer_route).to be_present
        expect(transfer_route['segments'].first['destination_iata']).to eq('OVB')
        expect(transfer_route['segments'].last['origin_iata']).to eq('OVB')
      end
    end

    context 'with missing parameters' do
      %w[carrier origin_iata destination_iata departure_from departure_to].each do |param|
        it "returns 422 when #{param} is missing" do
          invalid_params = valid_params.except(param.to_sym)
          post '/routes/search', params: invalid_params, as: :json
          
          expect(response).to have_http_status(:unprocessable_content)
          expect(JSON.parse(response.body)['error']).to include("Missing params: #{param}")
        end
      end
    end

    context 'with invalid date format' do
      it 'returns 422 for invalid departure_from' do
        invalid_params = valid_params.merge(departure_from: 'invalid-date')
        post '/routes/search', params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to include('Invalid date: invalid-date')
      end

      it 'returns 422 for invalid departure_to' do
        invalid_params = valid_params.merge(departure_to: 'invalid-date')
        post '/routes/search', params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to include('Invalid date: invalid-date')
      end
    end

    context 'with no routes found' do
      before do
        PermittedRoute.destroy_all
        Segment.destroy_all
      end

      it 'returns empty array' do
        post '/routes/search', params: valid_params, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'with different carrier' do
      let(:params) { valid_params.merge(carrier: 'SU') }

      before do
        create(:permitted_route, carrier: 'SU', origin_iata: 'UUS', destination_iata: 'DME', direct: true)
        create(:segment, airline: 'SU', origin_iata: 'UUS', destination_iata: 'DME', 
               std: Time.zone.parse('2024-01-02 10:00:00'), 
               sta: Time.zone.parse('2024-01-02 14:00:00'))
      end

      it 'returns routes for the specified carrier' do
        post '/routes/search', params: params, as: :json
        
        routes = JSON.parse(response.body)
        expect(routes.length).to eq(1)
        expect(routes.first['segments'].first['carrier']).to eq('SU')
      end
    end

    context 'with different date range' do
      let(:params) { valid_params.merge(departure_from: '2024-01-05', departure_to: '2024-01-06') }

      before do
        create(:segment, airline: 'S7', origin_iata: 'UUS', destination_iata: 'DME', 
               std: Time.zone.parse('2024-01-05 10:00:00'), 
               sta: Time.zone.parse('2024-01-05 14:00:00'))
      end

      it 'returns routes within the specified date range' do
        post '/routes/search', params: params, as: :json
        
        routes = JSON.parse(response.body)
        expect(routes.length).to eq(1)
        expect(routes.first['departure_time']).to include('2024-01-05')
      end
    end

    context 'with UUS → NOZ route' do
      let(:noz_params) do
        {
          carrier: 'S7',
          origin_iata: 'UUS',
          destination_iata: 'NOZ',
          departure_from: '2024-01-01',
          departure_to: '2024-01-07'
        }
      end

      it 'returns successful response for NOZ route' do
        post '/routes/search', params: noz_params, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
      end

      it 'returns routes for NOZ destination' do
        post '/routes/search', params: noz_params, as: :json
        
        routes = JSON.parse(response.body)
        expect(routes).to be_an(Array)
        expect(routes.length).to eq(1)
        expect(routes.first['origin_iata']).to eq('UUS')
        expect(routes.first['destination_iata']).to eq('NOZ')
      end

      it 'returns properly formatted NOZ route data' do
        post '/routes/search', params: noz_params, as: :json
        
        route = JSON.parse(response.body).first
        expect(route).to include(
          'origin_iata' => 'UUS',
          'destination_iata' => 'NOZ',
          'departure_time' => anything,
          'arrival_time' => anything,
          'segments' => anything
        )
        expect(route['segments']).to be_an(Array)
        expect(route['segments'].length).to eq(1)
      end
    end
  end
end
