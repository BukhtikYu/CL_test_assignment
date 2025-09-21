require 'rails_helper'

RSpec.describe RoutesController, type: :controller do
  describe 'POST #search' do
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
      it 'returns a successful response' do
        post :search, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON response' do
        post :search, params: valid_params
        expect(response.content_type).to include('application/json')
      end

      it 'returns an array of routes' do
        post :search, params: valid_params
        expect(JSON.parse(response.body)).to be_an(Array)
      end
    end

    context 'with missing parameters' do
      %w[carrier origin_iata destination_iata departure_from departure_to].each do |param|
        it "returns error when #{param} is missing" do
          invalid_params = valid_params.except(param.to_sym)
          post :search, params: invalid_params
          
          expect(response).to have_http_status(:unprocessable_content)
          expect(JSON.parse(response.body)['error']).to include("Missing params: #{param}")
        end
      end
    end

    context 'with invalid date format' do
      it 'returns error for invalid departure_from date' do
        invalid_params = valid_params.merge(departure_from: 'invalid-date')
        post :search, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to include('Invalid date: invalid-date')
      end

      it 'returns error for invalid departure_to date' do
        invalid_params = valid_params.merge(departure_to: 'invalid-date')
        post :search, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to include('Invalid date: invalid-date')
      end
    end

    context 'with empty parameters' do
      it 'returns error when carrier is blank' do
        invalid_params = valid_params.merge(carrier: '')
        post :search, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to include('Missing params: carrier')
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
        post :search, params: noz_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns routes for NOZ destination' do
        post :search, params: noz_params
        routes = JSON.parse(response.body)
        expect(routes).to be_an(Array)
        expect(routes.length).to eq(1)
        expect(routes.first['destination_iata']).to eq('NOZ')
      end
    end
  end
end
