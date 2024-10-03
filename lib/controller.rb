class Controller
  # @param money [Integer]
  # @param travel_routes [Array<Hash>]
  # @param pods [Hash] { id => [props] }
  # @param new_buildings [Array<Array>] [[], []]
  #
  # @return [String] the improvement command(s) to undertake
  def call(money:, travel_routes:, pods:, new_buildings:)
    @money = money
    @travel_routes = travel_routes
    @pods = pods
    @new_buildings = new_buildings

    "TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2 0 1 0 2"
  end
end
