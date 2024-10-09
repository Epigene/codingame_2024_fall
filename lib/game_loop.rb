debug "Game starts!"
# game loop
loop do
  money = gets.to_i
  debug("Money: #{money}")

  num_connections = gets.to_i
  debug("Number of connections: #{num_connections}", 1)

  connections = []
  num_connections.times do
    building_id_1, building_id_2, cap = gets.split.map(&:to_i)
    route = {b_id_1: building_id_1, b_id_2: building_id_2, cap: cap}
    connections << route
    # debug("  #{route},", 1)
  end

  num_pods = gets.to_i
  debug("Number of pods: #{num_pods}", 1)

  pods = {}
  num_pods.times do
    pod_props = gets.chomp.split(" ").map(&:to_i)
    pods[pod_props.first] = pod_props[1..]

    # debug("  #{pod_props.first} => #{pod_props[1..]},", 1)
  end

  num_new_buildings = gets.to_i
  debug("Number of new buildings: #{num_new_buildings}")

  new_buildings = []
  num_new_buildings.times do
    building_properties = gets.chomp
    new_buildings << (bd = building_properties.split(" ").map(&:to_i))
  end

  puts controller.call(money: money, connections: connections, pods: pods, new_buildings: new_buildings)
end
