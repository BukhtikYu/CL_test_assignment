class RouteBuilder
  def initialize(segment_candidates:)
    @candidates = segment_candidates
  end

  def build
    return [] if @candidates.blank? || @candidates.any?(&:empty?)

    # Start with all possible first segments
    routes = @candidates.first.map { |seg| [seg] }
    
    # For each subsequent leg, build valid connections
    @candidates[1..-1].each do |next_leg|
      next_routes = routes.flat_map do |route|
        next_leg.filter_map { |seg| route + [seg] if ConnectionTimeValidator.valid?(route.last.sta, seg.std) }
      end
      
      return [] if next_routes.empty?
      routes = next_routes
    end
    
    routes
  end
end