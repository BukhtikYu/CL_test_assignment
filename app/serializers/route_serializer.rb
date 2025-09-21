class RouteSerializer
  def initialize(segments)
    @segments = segments
  end

  def as_json
    {
      'origin_iata' => @segments.first.origin_iata,
      'destination_iata' => @segments.last.destination_iata,
      'departure_time' => @segments.first.std&.iso8601,
      'arrival_time' => @segments.last.sta&.iso8601,
      'segments' => @segments.map { |segment| serialize_segment(segment) }
    }
  end

  private

  def serialize_segment(segment)
    {
      'carrier' => segment.airline,
      'segment_number' => segment.segment_number,
      'origin_iata' => segment.origin_iata,
      'destination_iata' => segment.destination_iata,
      'std' => segment.std&.iso8601,
      'sta' => segment.sta&.iso8601
    }
  end
end
