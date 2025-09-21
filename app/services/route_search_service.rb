class RouteSearchService
  def initialize(carrier:, origin_iata:, destination_iata:, departure_from:, departure_to:)
    @carrier = carrier
    @origin = origin_iata
    @destination = destination_iata
    @departure_from = departure_from
    @departure_to = departure_to

    @segment_finder = SegmentFinder.new(
      carrier: carrier,
      departure_from: departure_from,
      departure_to: departure_to
    )
  end

  def call
    permitted_routes = PermittedRouteChecker.new(
      carrier: @carrier,
      origin_iata: @origin,
      destination_iata: @destination
    ).routes
    
    # Cache direct routes to avoid repeated queries
    @direct_routes = nil
    @direct_routes_used = false
    
    results = []
    permitted_routes.find_each do |route|
      if route.direct && !@direct_routes_used
        @direct_routes = build_direct_routes
        @direct_routes_used = true
        results.concat(@direct_routes)
      end
      
      if route.transfer_iata_codes.present?
        results.concat(build_transfer_routes(route))
      end
    end
    results
  end

  private

  def build_direct_routes
    @segment_finder
      .find_direct_segments(origin_iata: @origin, destination_iata: @destination)
      .to_a
      .map { |segment| RouteSerializer.new([segment]).as_json }
  end

  def build_transfer_routes(route)
    transfer_codes = route.transfer_iata_codes || []

    transfer_codes.flat_map do |code|
      legs = @segment_finder.build_route_legs(@origin, [code], @destination)
      segments_by_leg = @segment_finder.find_segments_for_legs(legs)
      
      # Convert hash to array of arrays for RouteBuilder
      segment_candidates = legs.map { |leg| segments_by_leg[leg] || [] }


      RouteBuilder.new(segment_candidates: segment_candidates)
                  .build
                  .map { |segments| RouteSerializer.new(segments).as_json }
    end
  end
end
