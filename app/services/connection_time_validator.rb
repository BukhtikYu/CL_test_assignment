class ConnectionTimeValidator
  MIN_CONNECTION_TIME = 480   # 8 hours in minutes
  MAX_CONNECTION_TIME = 2880  # 48 hours in minutes

  def self.valid?(arrival_time, departure_time)
    return false unless arrival_time && departure_time
    return false if departure_time < arrival_time

    layover = (departure_time - arrival_time) / 60 # convert seconds to minutes
    layover.between?(MIN_CONNECTION_TIME, MAX_CONNECTION_TIME)
  end
end
