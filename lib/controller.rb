class Controller
  POD_COST = 1_000
  TP_COST = 5_000
  REPLACEMENT_COST = 250
  MAX_BUILDINGS = 150
  MAX_TUBES = 5 # per node. + 1 teleporter possibly

  attr_reader :buildings # Hash of id => {type: 0, x: bd[2], y: bd[3], astronauts: astronauts, connections: {in: {}, out: {}}} pairs
  attr_reader :buildings_by_type # Hash of `type => Set` pairs

  # attr_reader :pads # folded into :buildings_by_type[0]
  attr_reader :modules # Set of module ids to look up in :buildings hash

  attr_accessor :money
  attr_reader :connections # Array<Hash> # [{:b_id_1=>3, :b_id_2=>2, :cap=>1}]
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

      #== money calcs
      @money = money
      if !@expected_money.nil? && @expected_money != @money
        debug("Expected money to be #{@expected_money}, but got #{@money - @expected_money} more - #{@money}")
      end
      #==

      @connections = connections
      @pods = pods
      @new_buildings = new_buildings

      update_building_list!(new_buildings)

      redo_underutilized_pods
      connect_pads_to_modules
      build_teleports

      @command = commands.any? ? commands.join(";") : "WAIT"
    end

    debug("Took #{(time * 1000).round}ms to execute, ended with #{self.money} money, next interest will be #{@expected_money = (self.money * 1.1).floor}", 0)

    @command
  end

  private

  def redo_underutilized_pods
    pods.each_pair do |id, data|
      time = Benchmark.realtime do
        redo_underutilized_pod(id, data)
      end
      report_time(time, "process underutilized_pod##{id}")
    end

    nil
  end

  def redo_underutilized_pod(id, data) # 42, [20, 0, 1, 0, 1]
    return unless pod_underutilized?(data)
    return if (unconnected_types = pad_unconnected_types(data[1])).none?

    connection_options = unconnected_types.each_with_object({}) do |type, mem|
      mem.merge!(connection_options(data[1], buildings_by_type[type]))
    end

    return if connection_options.none?

    money_after_pod = money - REPLACEMENT_COST

    connection_options.sort_by do |k, data|
      [-data[:point_ratio], data[:cost], data[:existing_connections]]
    end.find do |k, d|
      next if _too_expensive = (money_after_pod - d[:cost]).negative?

      commit_purchase("TUBE #{k}", cost: d[:cost])

      # remove existing route
      commit_destruction(id)

      # rebuild route, combining existing and new connection
      route = pod_route_from_fragments(data[1], _modules = data[2..].uniq - [data[1]] + [d[:module_id]])
      commit_purchase("POD #{id} #{route}", cost: POD_COST)
    end
  end

  # VERY naive strat, connects pads directly to modules of matching color nauts.
  def connect_pads_to_modules
    pads_by_potential.each do |id|
      break if self.money < 1000

      time = Benchmark.realtime do
        connect_pad_to_modules(id)
      end
      report_time(time, "process pad#{id} connecting")
    end
  end

  def connect_pad_to_modules(id)
    pad = buildings[id]

    if one_type_pad_already_connected?(pad)
      debug("Pad##{id} seems to already have a connection to same-color module")
      return
    end

    connection_options = connection_options(id, modules)

    return if connection_options.none?

    conn_fragments = []
    money_after_pod = money - POD_COST

    types_connected = []
    connection_options.sort_by do |k, data|
      [-data[:point_ratio], data[:cost], data[:existing_connections]]
    end.each do |k, data|
      next if _too_expensive = (money_after_pod - data[:cost]).negative?

      type = buildings[data[:module_id]][:type]
      next if _type_already_connected = types_connected.include?(type)

      money_after_pod -= data[:cost]
      conn_fragments << k
      types_connected << buildings[data[:module_id]][:type]
    end

    # using only as many connections as there are astronaut types arriving
    conn_fragments = conn_fragments.first(buildings[id][:astronauts].keys.size).first(MAX_TUBES)
    return if conn_fragments.none?

    conn_fragments.each do |fragment|
      commit_purchase("TUBE #{fragment}", cost: connection_options[fragment][:cost])
    end

    route = pod_route_from_fragments(id, conn_fragments.map { |f| f.split(" ").last.to_i })
    command = "POD #{42+pods.size} #{route}"
    commit_purchase(command, cost: POD_COST)
  end

  def build_teleports
    pads_by_tp_potential.each do |id|
      next if money < TP_COST
      next if building_has_teleport?(id)

      # pad = buildings[id]
      types = pad_unconnected_types(id)
      next if types.none?

      options = connection_options(id, buildings_by_type[types.first], check_vision: false, can_receive_tp: true)

      next if options.none?

      fragment, _meta = options.sort_by do |k, data|
        [data[:existing_connections], -data[:cost]]
      end.first

      command = "TELEPORT #{fragment}"
      commit_purchase(command, cost: TP_COST)
    end
  end

  # @param id [Id] # pad id
  # @return Hash # { "0 1" => {metadata}, ..}
  def connection_options(id, module_ids, check_vision: true, can_receive_tp: nil)
    pad = buildings[id]
    connection_options = {}

    modules.each do |module_id|
      house = buildings[module_id]
      if can_receive_tp && building_has_teleport?(module_id)
        next
      elsif !can_receive_tp && check_vision && building_tube_connections_maxed?(module_id)
        next
      end
      next if check_vision && !vision?(from: id, to: module_id)
      next if _no_matching_nauts = (pad[:astronauts].keys & [house[:type]]).empty?
      next if _already_connected = !pad[:connections].nil? && connections.find { _1[:b_id_1] == id && _1[:b_id_2] == module_id }

      distance = Segment[
        Point[pad[:x], pad[:y]], Point[house[:x], house[:y]]
      ].length

      cost = (distance * 10).floor

      conn_fragment = "#{id} #{module_id}"

      # naive for now, simply the number of nauts to move
      point_potential = pad[:astronauts][house[:type]]
      point_ratio = (point_potential.to_f / cost.to_f).round(4)

      connection_options[conn_fragment] = {
        module_id: module_id,
        cost: cost, point_potential: point_potential,
        point_ratio: point_ratio,
        existing_connections: house.fetch(:connections, {}).fetch(:in, {}).size
      }
      debug("Connecting Pad##{id} to Module##{module_id} at distance #{distance} would cost #{cost}")
    end

    connection_options
  end

  def building_tube_connections_maxed?(module_id)
    buildings[module_id].fetch(:connections, {}).fetch(:in, {}).values.count(&:positive?) >= MAX_TUBES
  end

  # Vision can be interfered with by other nodes on visibility line, and by tubes crossing
  #
  # @param from/to [Id] node id
  def vision?(from:, to:)
    vision_segment = Segment[
      Point[buildings[from][:x], buildings[from][:y]],
      Point[buildings[to][:x], buildings[to][:y]]
    ]

    obscured_by_other_node = buildings.except(from, to).find do |id, data|
      Point[data[:x], data[:y]].on_segment?(vision_segment.p1, vision_segment.p2)
    end

    return false if obscured_by_other_node

    obscured_by_tube = connections.find do |conn|
      next if conn[:cap].zero?

      # tubes originating from either point cannot obscure path between them
      next if ([from, to] & [conn[:b_id_1], conn[:b_id_2]]).any?

      b1 = buildings[conn[:b_id_1]]
      b2 = buildings[conn[:b_id_2]]

      tube_segment = Segment[
        Point[b1[:x], b1[:y]], Point[b2[:x], b2[:y]]
      ]

      vision_segment.intersect?(tube_segment)
    end

    return false if obscured_by_tube

    true
  end

  # @param root [Id]
  # @param modules Array<id>
  def pod_route_from_fragments(root, modules)
    base = modules.map { "#{root} #{_1}" }.join(" ")

    ([base] * 10).join(" ").split(" ").first(21).join(" ")
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
      connections << {:b_id_1=>ids.first, :b_id_2=>ids[1], :cap=>1}
      ensure_connection(*ids, cap: 1)
      ensure_connection(*ids.reverse, cap: 1)
    elsif command.start_with?("TELE")
      ids = command.split(" ").last(2).map(&:to_i)
      connections << {:b_id_1=>ids.first, :b_id_2=>ids[1], :cap=>0}
      ensure_connection(*ids, cap: 0)
    end

    debug("Committing to building #{command} at a cost of #{cost}, leaving #{self.money} in the bank")
  end

  # @param id [Id] pod id
  def commit_destruction(id)
    self.money += 750
    pods[id] = nil
    commands << "DESTROY #{id}"
    debug("Committing to destroying Pod##{id} regaining 750 == #{self.money} in the bank")
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

  # Sorts pads descending by the highest number of any one type of naut arriving, tiebreaking
  # by preferring pads with lower-id astronauts incoming
  #
  # @return [Array<Id>]
  def pads_by_potential
    pads.sort_by do
      type, count = buildings[_1][:astronauts].max_by { |_k, v| v }

      [-count, type]
    end
  end

  # reverse tiebreak from #pads_by_potential - we want pads with most stranded nauts of higher
  # type because they will have a harder time getting into pods.
  def pads_by_tp_potential
    pads.sort_by do
      type, count = buildings[_1][:astronauts].max_by { |_k, v| v }

      [-count, -type]
    end
  end

  def pod_underutilized?(data)
    root = data[1]
    unique_stops = data[1..].uniq - [root]

    return if unique_stops.size >= 4

    untransfered = buildings[root][:astronauts].dup

    unique_stops.each do |module_id|
      untransfered[buildings[module_id][:type]] = 0
    end

    untransfered.values.sum / buildings[root][:astronauts].values.sum.to_f >= 0.4
  end

  # @param id [Id] Pad building id
  # @return [Array<Integer>] # a sorted array of types lacking connections
  def pad_unconnected_types(id)
    pad = buildings[id]
    connected_types = pad.fetch(:connections, {}).fetch(:out, {}).keys.map { buildings[_1][:type] }

    (pad[:astronauts].keys - connected_types).sort_by { pad[:astronauts][_1] }
  end

  def building_has_teleport?(id)
    buildings[id].fetch(:connections, {}).fetch(:out, {}).values.any?(&:zero?) ||
    buildings[id].fetch(:connections, {}).fetch(:in, {}).values.any?(&:zero?)
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
    buildings.first(30).each do |id, data|
      debug("  #{id} => #{data},")
    end
    if buildings.size > 30
      debug("  .. more omitted ..")
    end

    nil
  end
end
