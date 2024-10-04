class Controller
  attr_reader :buildings # Hash of id => {type: 0, x: bd[2], y: bd[3], astronauts: astronauts} pairs
  attr_reader :buildings_by_type # Hash of `type => Set` pairs

  # attr_reader :pads # Set of pad ids to look up in :buildings hash
  attr_reader :modules # Set of module ids to look up in :buildings hash

  attr_reader :money, :travel_routes, :pods, :new_buildings
  attr_reader :command # a mutable array to collect the various moves

  # @param buildings [Hash] allows setting the game-state to whatever move with previous buildings
  def initialize(buildings: {})
    @buildings = buildings
    @pads = [].to_set
    @modules = [].to_set
    @buildings_by_type = Hash.new { |h, k| h[k] = Set.new }
  end

  # @param money [Integer]
  # @param travel_routes [Array<Hash>]
  # @param pods [Hash] { id => [props] }
  # @param new_buildings [Array<Array>] [[], []]
  #
  # @return [String] the improvement command(s) to undertake
  def call(money:, travel_routes:, pods:, new_buildings:)
    @command = []
    @money = money
    @travel_routes = travel_routes
    @pods = pods
    @new_buildings = new_buildings

    update_building_list!(new_buildings)

    connect_pad_to_modules

    # "TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2"
    command.join(";")
  end

  private

  def connect_pad_to_modules
    pads.each do |id|
      conn_fragments = []
      modules.each do |module_id|
        distance = Segment[
          Point[buildings[id][:x], buildings[id][:y]],
          Point[buildings[module_id][:x], buildings[module_id][:y]]
        ].length

        debug("Connecting Pad##{id} to Module##{module_id} at distance #{distance} would cost #{(distance * 10).floor}")

        conn_fragment = "#{id} #{module_id}"
        conn_fragments << conn_fragment
        command << "TUBE #{conn_fragment}"
      end

      scaling = 20/conn_fragments.size
      command << "POD 42 #{(conn_fragments * (scaling / 2).floor).join(" ")}"
    end
  end

  def pads
    buildings_by_type[0]
  end

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
          buildings_by_type[bd[0]] << id

          {type: bd[0], x: bd[2], y: bd[3]}
        end
    end

    nil
  end
end
