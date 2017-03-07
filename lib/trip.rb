require 'csv'
module RideShare
  class Trip
    attr_reader :id, :driver_id, :rider_id, :date, :rating

    def initialize(info)
      @id = info[:id]
      @driver_id = info[:driver_id]
      @rider_id = info[:rider_id]
      @date = info[:date]
      @rating = info[:rating]
    end

    def self.all(csv_file)
      trips = CSV.read(csv_file)
      trips.shift
      trips.map! do |trip_info|
        trip = Hash.new
        trip[:id] = trip_info[0].to_i
        trip[:driver_id] = trip_info[1].to_i
        trip[:rider_id] = trip_info[2].to_i
        # want date to be date object?
        trip[:date] = trip_info[3]
        trip[:rating] = trip_info[4].to_i
        trip_info = trip
      end

      trips.map! { |info| self.new(info) }
      return trips
    end

    # these two method are very similar - maybe should be writing one method
    # or a helper method
    def self.find_by_driver(id, csv_file)
      trips = all(csv_file)
      trips.map! { |trip| trip if trip.driver_id == id }.compact!
      return trips
    end

    def self.find_by_rider(id, csv_file)
      trips = all(csv_file)
      trips.map! { |trip| trip if trip.rider_id == id }.compact!
      return trips
    end
  end
end
# p RideShare::Trip.find_by_driver(2, '../support/trips.csv')
