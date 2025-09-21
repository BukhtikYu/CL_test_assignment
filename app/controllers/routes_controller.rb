class RoutesController < ApplicationController
    before_action :check_required_params, only: :search
    before_action :parse_departure_times, only: :search
  
    def search
      results = RouteSearchService.new(
        carrier: params[:carrier],
        origin_iata: params[:origin_iata],
        destination_iata: params[:destination_iata],
        departure_from: @departure_from,
        departure_to: @departure_to
      ).call
  
      render json: results
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  
    private
  
    def search_params
      params.permit(:carrier, :origin_iata, :destination_iata, :departure_from, :departure_to)
    end
  
    def check_required_params
      missing = %i[carrier origin_iata destination_iata departure_from departure_to].select { |k| params[k].blank? }
      return if missing.empty?
  
        render json: { error: "Missing params: #{missing.join(', ')}" }, status: :unprocessable_content
    end
  
    def parse_departure_times
      @departure_from = parse_date(params[:departure_from])
      @departure_to   = parse_date(params[:departure_to])
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  
    def parse_date(str)
      date = Time.zone.parse(str)
      raise StandardError, "Invalid date: #{str}" unless date
      date
    end
end


