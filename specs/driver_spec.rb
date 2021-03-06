require_relative './spec_helper'
require_relative '../lib/driver'

describe "Driver" do

  describe "Driver#initialize" do
    before do
      driver_info = {
        id: 1,
        name: 'Bernardo Prosacco',
        vin: 'WBWSS52P9NEYLVDE9'
      }
      @new_driver = RideShare::Driver.new(driver_info)
    end

    it "returns a driver instance" do
      @new_driver.must_be_instance_of RideShare::Driver
    end

    it "assigns instance variables: id, name, and vin" do
      @new_driver.id.must_equal 1
      @new_driver.name.must_equal 'Bernardo Prosacco'
      @new_driver.vin.must_equal 'WBWSS52P9NEYLVDE9'
    end
  end

  describe "Driver#all" do

    # Examples of driver data:
    # driver_id,name,vin
    # 1,Bernardo Prosacco,WBWSS52P9NEYLVDE9
    # 2,Emory Rosenbaum,1B9WEX2R92R12900E
    # 3,Daryl Nitzsche,SAL6P2M2XNHC5Y656

    # instance variables are assigned to use throughout specs
    before do
      csv_file = './support/drivers.csv'
      data = FileData.new(csv_file)
      @drivers_data = data.read_csv_and_remove_headings

      @bad_data = {
                    bad_id: [['2', 'Emory Rosenbaum', '1B9WEX2R92R12900E'], ['ten', 'name', 'WBWSS52P9NEYLVDE9']],
                    bad_vin: [['10', 'name', 'WBWSS52P9NE']],
                    empty_array: [],
                    empty_nested_arrays: [[],[],[]],
                    missing_part: [['10', 'name']],
                    bad_name: [['3', 'a', 'WBWSS52P9NEYLVDE9']]
                   }
      @data_with_duplicate = [
                                ['500', 'Jane Doe', 'WX1234567890ABCDE'],
                                ['501', 'John Smith','WX1234567890ABCDE'],
                                ['502', 'Cyn Bin','ZZ1234567890ABCDE'],
                                ['502', 'Ms. Squishy','YY1234567890ABCDE'],
                                ['505', 'Travis Crosby','XX1234567890ABCDE']
                             ]
    end

    let(:drivers) { RideShare::Driver.all(@drivers_data) }

    it "returns an array" do
      drivers.must_be_instance_of Array
    end

    it "has instances of drivers in the array" do
      drivers.each { |driver| driver.must_be_instance_of RideShare::Driver }
    end

    it "has the same number of driver instances as the CSV file" do
      drivers.length.must_equal 100
    end

    it "raises an error if given bad data for driver_id" do
      proc { RideShare::Driver.all(@bad_data[:bad_id]) }.must_raise ArgumentError
    end

    it "raises an error if given bad data for vin " do
      err = proc {
                   RideShare::Driver.all(@bad_data[:bad_vin])
                 }.must_raise ArgumentError
      err.message.must_equal "Vin must be 17 characters"
    end

    it "raises an error if given a info missing parts" do
      err = proc {
                   RideShare::Driver.all(@bad_data[:missing_part])
                 }.must_raise ArgumentError
      err.message.must_equal "Driver info must have 3 parts"
    end

    it "raises an error if given an empty array" do
      err = proc {
                   RideShare::Driver.all(@bad_data[:empty_array])
                 }.must_raise ArgumentError
      err.message.must_equal "Data is empty array"
    end

    it "raises an error if given empty nested arrays" do
      err = proc {
                   RideShare::Driver.all(@bad_data[:empty_nested_arrays])
                 }.must_raise ArgumentError
      err.message.must_equal "Driver info must have 3 parts"
    end

    it "raises an error if given improper name" do
      err = proc {
                   RideShare::Driver.all(@bad_data[:bad_name])
                 }.must_raise ArgumentError
      err.message.must_equal "Name length is under 1"
    end

    it "raises an error if two drivers have same id" do
      err = proc {
              RideShare::Driver.all(@data_with_duplicate)
           }.must_raise ArgumentError
      err.message.must_equal "There are two drivers with the same id: 502"
    end
  end

  describe "Driver#find" do

    it "requires one argument" do
      proc {
        RideShare::Driver.find()
      }.must_raise ArgumentError
    end

    it "returns a driver instance when passed a valid id" do
      RideShare::Driver.find(7).must_be_instance_of RideShare::Driver
    end

    it "returns nil when given a driver id that does not exists" do
      RideShare::Driver.find(900).must_be_nil
    end

    it "can find the first driver from the CSV" do
      first_driver_in_array = RideShare::Driver.find(1)
      first_driver_in_array.name.must_equal "Bernardo Prosacco"
      first_driver_in_array.id.must_equal 1
      first_driver_in_array.vin.must_equal 'WBWSS52P9NEYLVDE9'
    end

    it "cant find the last driver from the CSV" do
      last_driver = RideShare::Driver.find(100)
      last_driver.name.must_equal "Minnie Dach"
      last_driver.id.must_equal 100
      last_driver.vin.must_equal 'XF9Z0ST7X18WD41HT'
    end
  end

                        ###########################
                        ## instance method specs ##
                        ###########################

  # wrote this loop to sort trips by driver - this returns an array of arrays
  # each nested array contains trips for same driver - can use to find driver
  # with one trip and the most trips
  def sort_trips_by_driver(trips, number_of_drivers)
    trips_sorted_by_driver_id = Array.new(number_of_drivers) { |i| i = [] }
    trips.each do |trip|
      number_of_drivers.times do |i|
        trips_sorted_by_driver_id[i] << trip if trip.driver_id == i
      end
    end
    trips_sorted_by_driver_id
  end

  before do
    # hand calculated driver_id 21's average: 30.0/11 = 2.73
    @driver_id = 21
    trips = RideShare::Trip.all
    number_of_drivers = RideShare::Driver.all.length
    trips_sorted_by_driver_id = sort_trips_by_driver(trips, number_of_drivers)
    # drivers 27 and 37 have only 1 trip - driver 27's one trip rating is 1
    @driver_with_one_trip = trips_sorted_by_driver_id.min_by { |array| array.length }
    # drivers: 54 has most trips (12 of them)
    @driver_with_most_trips = trips_sorted_by_driver_id.max_by { |array| array.length }
  end

  let(:drivers) {RideShare::Driver.all}
  let(:driver_know_avg) { RideShare::Driver.find(@driver_id) }
  let(:driver_no_trips) { RideShare::Driver.find(100) }
  let(:driver_1_trip) { RideShare::Driver.find(@driver_with_one_trip[0].driver_id)}
  let(:drivers_with_most_trips) {RideShare::driver.find(@drivers_with_most_trips[0].driver_id)}

  describe "Driver#get_trips" do

    it "returns an array of trip instances" do
      driver_know_avg.get_trips.must_be_instance_of Array
      driver_know_avg.get_trips.each { |trip| trip.must_be_instance_of RideShare::Trip }
    end

    it "each trip instance has the same driver id" do
      driver_know_avg.get_trips.each { |trip| trip.driver_id.must_equal @driver_id }
    end
  end

  describe "Driver#calculate_average_rating" do

    # used sample here to get a sample of the trips and makes sure they are
    # returning an average in the expected range of 1-5
    # could test all drivers for this data, but if data was significantly larger
    # it might take too much time to test them all
    it "returns a float between 1 and 5" do
      drivers.sample(25).each do |driver|
        return nil if driver.calculate_average_rating.nil?
        driver.calculate_average_rating.must_be :>=, 1
        driver.calculate_average_rating.must_be :<=, 5
        driver.calculate_average_rating.must_be_instance_of Float
      end
    end

    it "calculates the correct average" do
      # this is the average for driver_id 21 calculated by hand
      driver_know_avg.calculate_average_rating.must_equal 2.73
    end

    it "returns nil if there are no trips for driver" do
      driver_no_trips.calculate_average_rating.must_be_nil
    end

    it "returns correct average for driver with 1 trip" do
      driver_1_trip.calculate_average_rating.must_equal 1.0
    end
  end
end
