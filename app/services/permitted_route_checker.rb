class PermittedRouteChecker
  def initialize(carrier:, origin_iata:, destination_iata:)
    @carrier = carrier
    @origin  = origin_iata
    @destination = destination_iata
  end

  def direct_routes_allowed?
    routes.direct.exists?
  end

  def transfer_routes
    transfer_codes(routes.with_transfer)
  end

  def all_transfer_codes
    transfer_codes(routes)
  end

  def routes
    @routes ||= PermittedRoute.for_trip(
      carrier: @carrier,
      origin: @origin,
      destination: @destination
    )
  end

  def transfer_codes(scope)
    scope.pluck(:transfer_iata_codes).flatten.compact
  end
end
