debug "Game starts!"
# game loop
loop do
  money = gets.to_i
  debug("Money: #{money}")

  num_travel_routes = gets.to_i
  debug("Number of routes: #{num_travel_routes}")

  travel_routes = []
  num_travel_routes.times do
    building_id_1, building_id_2, cap = gets.split.map(&:to_i)
    route = {b_id_1: building_id_1, b_id_2: building_id_2, cap: cap}
    travel_routes << route
    debug("  #{route}")
  end

  num_pods = gets.to_i
  debug("Number of pods: #{num_pods}")

  pods = {}
  num_pods.times do
    pod_props = gets.chomp.split(" ").map(&:to_i)
    debug("  #{pod_props}")
    pods[pod_props.first] = pod_props[1..]
  end

  num_new_buildings = gets.to_i
  debug("Number of new buildings: #{num_new_buildings}")

  new_buildings = []
  num_new_buildings.times do
    building_properties = gets.chomp
    new_buildings << (bd = building_properties.split(" ").map(&:to_i))

    nauts =
      if bd[5]
        bd[5..].each_with_object(Hash.new(0)) { |num, mem| mem[num] += 1 }
      else
        nil
      end

    debug("  #{bd[0..4]} #{nauts}")
  end

  puts controller.call(money: money, travel_routes: travel_routes, pods: pods, new_buildings: new_buildings)
end
