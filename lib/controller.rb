class Controller
  attr_reader :buildings, :pads, :modules
  attr_reader :money, :travel_routes, :pods, :new_buildings

  # @param buildings [Hash] allows setting the game-state to whatever move with previous buildings
  def initialize(buildings: {})
    @buildings = buildings
    @pads = [].to_set
    @modules = [].to_set
  end

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

    update_building_list!(new_buildings)

    binding.pry

    "TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2 0 1 0 2"
  end

  private

  def update_building_list!(new_buildings)
    new_buildings.each do |bd| # moduleType buildingId coordX coordY, *
      id = bd[1]

      buildings[id] =
        if (_type = bd.first) == 0
          pads << id
          astronauts = bd[5..].each_with_object(Hash.new(0)) { |num, mem| mem[num] += 1 }

          {type: 0, x: bd[2], y: bd[3], astronauts: astronauts}
        else
          modules << id

          {type: bd[0], x: bd[2], y: bd[3]}
        end
    end

    nil
  end
end
