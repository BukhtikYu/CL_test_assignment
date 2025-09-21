class SegmentFinder
  def initialize(carrier:, departure_from:, departure_to:)
    @carrier = carrier
    @from = departure_from.beginning_of_day.utc
    @to   = departure_to.end_of_day.utc
  end

  def find_direct_segments(origin_iata:, destination_iata:)
    find_segments(origin_iata: origin_iata, destination_iata: destination_iata)
  end

  def find_segments_for_route(origin_iata:, destination_iata:)
    find_segments(origin_iata: origin_iata, destination_iata: destination_iata, extended: true)
  end

  def find_segments_for_legs(legs)
    return {} if legs.empty?
    
    unique_routes = legs.uniq
    
    window_end = @to + ConnectionTimeValidator::MAX_CONNECTION_TIME.minutes
    all_segments = Segment.by_airline(@carrier)
                          .by_routes(unique_routes)
                          .departing_between(from: @from, to: window_end)
                          .ordered_by_departure
                          .group_by { |seg| [seg.origin_iata, seg.destination_iata] }
    
    # Map back to legs
    legs.each_with_object({}) do |leg, result|
      result[leg] = all_segments[leg] || []
    end
  end

  def parse_transfer_codes(code)
    code.presence&.length == 3 ? [code] : code.to_s.scan(/.{3}/)
  end

  def build_route_legs(origin, transfer_codes, destination)
    waypoints = [origin] + transfer_codes.flat_map { |c| parse_transfer_codes(c) } + [destination]
    waypoints.each_cons(2).to_a
  end

  private

  def find_segments(origin_iata:, destination_iata:, extended: false)
    window_end = extended ? @to + ConnectionTimeValidator::MAX_CONNECTION_TIME.minutes : @to

    Segment.by_airline(@carrier)
           .by_route(origin: origin_iata, destination: destination_iata)
           .departing_between(from: @from, to: window_end)
           .ordered_by_departure
           .to_a
  end
end
