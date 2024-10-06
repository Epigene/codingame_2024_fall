class Controller
  POD_COST = 1_000
  TP_COST = 5_000
  MAX_BUILDINGS = 150
  MAX_TUBES = 5 # per node. + 1 teleporter possibly

  attr_reader :buildings # Hash of id => {type: 0, x: bd[2], y: bd[3], astronauts: astronauts, connections: {in: {}, out: {}}} pairs
  attr_reader :buildings_by_type # Hash of `type => Set` pairs

  # attr_reader :pads # folded into :buildings_by_type[0]
  attr_reader :modules # Set of module ids to look up in :buildings hash

  attr_accessor :money
  attr_reader :connections #
  attr_reader :pods, :new_buildings
  attr_reader :commands # a mutable array to collect the various moves

  # @param buildings [Hash] allows setting the game-state to whatever move with previous buildings
  def initialize(buildings: {})
    time = Benchmark.realtime do
      @buildings = buildings
      @pads = [].to_set
      @modules = [].to_set
      @buildings_by_type = Hash.new { |h, k| h[k] = Set.new }

      initialize_building_list!
    end

    debug("Took #{(time * 1000).round}ms to initialize", 0)
  end

  # @param money [Integer]
  # @param connections [Array<Hash>]
  # @param pods [Hash] { id => [props] }
  # @param new_buildings [Array<Array>] [[], []]
  #
  # @return [String] the improvement command(s) to undertake
  def call(money:, connections: [], pods: {}, new_buildings: [])
    time = Benchmark.realtime do
      @commands = []
      @money = money
      @connections = connections
      @pods = pods
      @new_buildings = new_buildings

      update_building_list!(new_buildings)

      connect_pads_to_modules

      @command = commands.any? ? commands.join(";") : "WAIT"
    end

    debug("Took #{(time * 1000).round}ms to execute", 0)

    @command
  end

  private

  # VERY naive strat, connects pads directly to modules of matching color nauts.
  def connect_pads_to_modules
    pads_by_potential.each do |id|
      break if self.money < 1000

      time = Benchmark.realtime do
        connect_pad_to_modules(id)
      end
      debug("Processing pad##{id} took #{(time * 1000).round}ms", 0)
    end
  end

  def connect_pad_to_modules(id)
    if one_type_pad_already_connected?(buildings[id])
      debug("Pad##{id} seems to already have a connection to same-color module")
      return
    end

    connection_options = {}

    modules.each do |module_id|
      next if _no_matching_nauts = (buildings[id][:astronauts].keys & [buildings[module_id][:type]]).empty?
      next if _already_connected = connections.find { _1[:b_id_1] == id && _1[:b_id_2] == module_id }

      distance = Segment[
        Point[buildings[id][:x], buildings[id][:y]],
        Point[buildings[module_id][:x], buildings[module_id][:y]]
      ].length

      cost = (distance * 10).floor

      conn_fragment = "#{id} #{module_id}"

      # naive for now, simply the number of nauts to move
      point_potential = buildings[id][:astronauts][buildings[module_id][:type]]
      point_ratio = (point_potential.to_f / cost.to_f).round(4)

      connection_options[conn_fragment] = {
        cost: cost, point_potential: point_potential,
        point_ratio: point_ratio,
        existing_connections: buildings[module_id].fetch(:connections, {}).fetch(:in, {}).size
      }
      debug("Connecting Pad##{id} to Module##{module_id} at distance #{distance} would cost #{cost}")
    end

    return if connection_options.none?

    conn_fragments = []
    money_after_pod = money - POD_COST

    connection_options.sort_by do |k, data|
      [-data[:point_ratio], data[:cost], data[:existing_connections]]
    end.each do |k, data|
      next if _too_expensive = (money_after_pod - data[:cost]).negative?

      money_after_pod -= data[:cost]
      conn_fragments << k
    end

    return if conn_fragments.none?

    # using only as many connections as there are astronaut types arriving
    conn_fragments = conn_fragments.first(buildings[id][:astronauts].keys.size)

    conn_fragments.first(buildings[id][:astronauts].keys.size).each do |fragment|
      commit_purchase("TUBE #{fragment}", cost: connection_options[fragment][:cost])
    end

    scaling = 20/conn_fragments.size
    command = "POD #{42+pods.size} #{(conn_fragments * (scaling / 2).floor).join(" ")}"
    commit_purchase(command, cost: POD_COST)
  end

  def commit_purchase(command, cost:)
    self.money -= cost
    commands << command

    if command.start_with?("POD")
      id = command.match(%r'\APOD (?<id>\d+)')[:id]
      stops = command.split("POD #{id} ").last.split(" ")

      pods[id.to_i] = [stops.size, *stops.map(&:to_i)]
    elsif command.start_with?("TUBE")
      ids = command.split(" ").last(2).map(&:to_i)
      ensure_connection(*ids, cap: 1)
      ensure_connection(*ids.reverse, cap: 1)
    end

    debug("Committing to building #{command} at a cost of #{cost}, leaving #{money} in the bank")
  end

  # upgrades capacities of 1 to 2 etc, but 0 is a TP and is never changed
  def ensure_connection(id1, id2, cap:)
    buildings[id1][:connections] ||= {}
    buildings[id1][:connections][:out] ||= {}

    if buildings[id1][:connections][:out][id2] == 0 || buildings[id1][:connections][:out][id2].to_i > cap
      # noop
    else
      buildings[id1][:connections][:out][id2] = cap
    end

    buildings[id2][:connections] ||= {}
    buildings[id2][:connections][:in] ||= {}
    buildings[id2][:connections][:in][id1] ||= cap

    if buildings[id2][:connections][:in][id1] == 0 || buildings[id2][:connections][:in][id1].to_i > cap
      # noop
    else
      buildings[id2][:connections][:in][id1] = cap
    end

    nil
  end

  def one_type_pad?(building)
    return false unless building[:type] == 0

    building[:astronauts].keys.size == 1
  end

  # This is naive, assumes any outgoing connections are directly to needed type
  def one_type_pad_already_connected?(building)
    one_type_pad?(building) && !building.dig(:connections, :out).nil?
  end

  def pads
    buildings_by_type[0]
  end

  # Sorts pads descending by the highest number of any one type of naut arriving
  #
  # @return [Array<Id>]
  def pads_by_potential
    pads.sort_by { -buildings[_1][:astronauts].values.max }
  end

  def initialize_building_list!
    buildings.each_pair do |id, data|
      buildings_by_type[data[:type]] << id
      modules << id if data[:type] != 0
    end

    nil
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

    debug("Buildings on map:")
    buildings.each_pair do |id, data|
      debug("  #{id} => #{data},")
    end

    nil
  end
end
