## Goal
The project is now official: Selenia City, the first city on the moon, will be inaugurated in 2050!

The definitive layout of the city hasn't been fully determined yet, so the architects are looking for a solution that could best adapt to all possible configurations.

After your victory in the planetary programming games, you were the first to be called to design the artificial intelligence that will develop the first transportation network on the moon.

## Rules
The game is played in *20* lunar months of *20* days each.

At the beginning of each month, you will receive resources as well as the list of new buildings constructed in Selenia City. You will then need to use your resources efficiently to connect the new buildings to the network, or reinforce the existing infrastructure.

## Transportation modes
There are two transportation modes on the lunar base: magnetic tubes and teleporters.

### Tubes
Magnetic tubes are built on the lunar ground and allow transport pods to carry astronauts through them. They are built in a straight line between two buildings and are bidirectional.

Two tubes cannot cross each other, and each building can only be connected to **at most 5** magnetic tubes. A magnetic tube cannot pass through a building without stopping there.

Initially, each tube can only accommodate a single pod at a time, which takes an entire day to travel through it (regardless of its length) while carrying a maximum of 10 passengers. It is however possible to upgrade tubes so they can be traversed by several pods simultaneously.

An upgraded tube
You will have the possibility to configure precisely the path of each transport pod, which can travel freely through the network of tubes.

### Teleporters
Teleporters provide a very efficient way of traveling, although they are more expensive to build than tubes. They allow astronauts to move instantly from a building to another, without limits on how many passengers can use it at once. The path of two teleporters can cross.

Astronauts teleporting
Since replication equipment is very bulky, each building can only accommodate a teleporter entrance or exit.

## Buildings
Buildings in Selenia City are organized on a rectangular area of 160 x 90 kilometers. Two types of buildings will exist in the city: lunar modules and landing pads.

### Lunar modules
The 20 types of lunar modules in Selenia City
There are several different types of lunar modules (laboratory, ground sampling site, observatory, ...) that will permanently house the astronauts.

You need to transport each astronaut to a building of the corresponding type in order to win points. There may exist several modules of the same type in Selenia City.

### Landing pads

Landing pads are buildings that work in a special way: at the beginning of each month, a rocket will drop a group of astronauts on each of them. The composition of the group is fixed: if for example a landing pad welcomes 5 lab technicians and 10 observatory employees, an identical group will arrive each month.

If several lunar modules have the same type as the astronaut, he may settle into any of them.

Your solution will score more points if it manages to balance the astronaut population well between modules of the same type

## Scoring
Your objective is to score as many points as possible before the end of the simulation.

Each astronaut reaching its target before the end of the lunar month will give you up to 100 points:

For speed: 50 points, from which are deducted the number of days needed by the astronaut to reach the destination.
For balancing the population: 50 points, from which are deducted the number of astronauts who have already reached the same module during the current lunar month. If it's negative, this score will be brought back to 0.

### Example 1:
An astronaut of type 4 arrives in Selenia City on the first day of the month, and immediately takes a teleporter that takes her from the landing pad to a building of type 4.

She is the first one to reach her base, you will score 100 points (50 speed points and 50 balancing points).

### Example 2:
An astronaut takes a pod through a magnetic tube on the first day to leave his landing pad, then a teleporter followed by another tube on the second day. He reaches his module as 60 astronauts have previously been installed in this building during that month.

He will earn you 48 points (48 speed points and no balancing point).

# Implementation
Each lunar month happens in 4 stages :

1. City parsing
At the beginning of each month, your code receives information about new constructions in Selenia City.

* On the first line, an integer resources representing the total amount of resources you currently have.
* On the next line, an integer numTravelRoutes, the number of routes (tubes or teleporters) currently present in the city.
* On the next numTravelRoutes lines, the description of a tube or teleporter as a list of three space-separated integers buildingId1, buildingId2 and capacity:
buildingId1 and buildingId2 are the ends of the tube or teleporter.
capacity equals 0 if the route is a teleporter, and represents the capacity of the tube otherwise.
* On the next line, an integer numPods, the number of transport pods currently present in the network of magnetic tubes.
* On the next numPods lines, the description of a pod as a list of space-separated integers:
The first integer is the unique identifier of the pod.
The second integer is the number numStops of stops in the pod's path.
The next numStops integers represent the pod's path, i.e. the identifiers of each building on its itinerary.
* On the next line, an integer numNewBuildings, the number of buildings that have just been constructed.
* On the next numNewBuildings lines, the description of a new building, as a list of space-separated integers. The format of each line depends on the building type:
* * If the building is a landing pad: 0 buildingId coordX coordY numAstronauts astronautType1 astronautType2 ...
* * Otherwise, the first number is positive and the building is a lunar module: moduleType buildingId coordX coordY
Here's an example of input data which could be provided to your program at the beginning of its turn, with an explanation of each line:

2. Transport infrastructure improvements
Your code can then transform the city through actions that allow you to build and improve its transportation network.

Allowed actions:
* TUBE buildingId1 buildingId2: create a magnetic tube between two buildings. The cost is 1 resource for each 0.1km of tube installed, rounded down.
* UPGRADE buildingId1 buildingId2: increase the capacity of a tube by 1. You will need to spend the initial construction cost multiplied by the new capacity. For example, if a tube initially cost 500 resources to build, you have to spend 1000 resources to improve its capacity to 2 pods, then 1500 resources for 3 pods, etc.
* TELEPORT buildingIdEntrance buildingIdExit: build a teleporter. This action costs 5,000 resources.
* POD podId buildingId1 buildingId2 buildingId3 ...: create a transport pod and define its path. The pod identifier must be included between 1 and 500. If the last stop is the same as the first, the pod will loop around the path indefinitely, otherwise it will remain in place after reaching its last stop. This action costs 1,000 resources.
* DESTROY podId: deconstruct a transport pod. This action gives you 750 resources back.
* WAIT: don't perform any action this turn.
In order to execute several actions during the same game turn, you can separate them with a semicolon like this: TELEPORT 12 34;TUBE 23 45;UPGRADE 23 45.

If an action is impossible (lacking sufficient resources, or if building a tube would cross the path of another for example), it will be ignored and a warning will display in the game console. In order to determine which actions have been performed successfully, your code can use the input data provided at the beginning of the following month.

Also note that tubes and teleporters are permanent and can never be removed. It is possible to change the path of a pod by deconstructing then rebuilding it on a different route, which costs 250 resources.

3. Astronaut movement
Once all modifications have been applied to the transport network, 20 days will happen during which astronauts move within the network autonomously towards their target modules.

# Movement simulation
Traversing a magnetic tube always takes one day, regardless of the distance. On a given network, we can then define the distance from one building to another as the minimal number of tubes needed to make the entire trip (teleporters can be used in said trip).

Astronauts plan their route in a naive way, by trying to move towards their nearest target module (or any nearest module if several exist). They will take any tube or teleporter available that takes them closer to their destination, without actually considering the pods scheduled on the following days to determine whether their trajectory is optimal or even feasible.

The movement phase happens in 4 steps each day:

Teleporters: each astronaut standing on a teleporter entrance will take it, if the exit building has a distance to the target less than or equal to the entrance building. Since teleportation is instantaneous, the astronaut can then take a magnetic tube in the same day.
Allocation of pods in magnetic tubes: it is possible that several pods are trying to move through a tube that has insufficient capacity to accommodate them all. In this case, pods with the smallest identifier are given priority, and the others remain in place until the next day.
Allocation of astronauts in pods: each astronaut tries to find a pod with a free seat that will move towards their destination (i.e. a strictly lower distance), and hops on board. Astronauts choose in order, the astronauts who come from a landing pad with lower identifier pick first. If several options can bring an astronaut closer to their target, the pod with the smallest identifier will be chosen.
Launch of all pods: each pod moves towards its next step with its astronauts on board, then all passengers disembark.

In the animation above, take the time to understand why each astronaut moves the way they do, sometimes in surprising ways:

On the first day, the red astronauts teleport to module 6, which seems counterintuitive to move "away" from their target module. However, buildings 4 and 6 are both 3 tubes away from their destination at building 0, and astronauts will always take a teleporter if it does not increase their distance to the target.
Green astronauts in landing pad 3 can move to either building 2 or 4, which are both 1 tube away from a green module. On the first day, 10 green astronauts take the pod from 3 to 4 due to their naive pathfinding algorithm, only to become stranded there until the end of the month because no pod will ever go from 4 to 1.
Remember that astronauts will only take a pod if it strictly lowers the distance to their target. On day 10, it can be surprising that blue astronauts move from 3 to 4, because both buildings seem to be the same distance away from their target at building 6. However, the distance from 4 to 6 is actually 0 due to the presence of a teleporter, since distance calculations will only count the minimal number of tubes to move from one building to another.

4. End of the lunar month
At the end of each month, all remaining astronauts disappear from the play area and all pods immediately return to their starting point. All unused resources yield a 10% interest (rounded down).

Constraints
During the game, at most 150 buildings will be constructed.
Each landing pad will welcome between 1 and 100 astronauts each month.
At most 1000 astronauts will arrive each month.
It is guaranteed that no building will be constructed on the path of an existing tube.
Your program has to return its list of actions within 500 milliseconds each turn (1000 milliseconds for the first turn).
It is guaranteed that each astronaut arriving on a landing pad will have at least 1 module of the same type already built.

