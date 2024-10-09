RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new(buildings: buildings) }
  let(:buildings) { {} }

  describe ".pod_route_from_fragments(root, *fragments)" do
    subject(:pod_route_from_fragments) { described_class.pod_route_from_fragments(root, *fragments) }

    let(:root) { 0 }

    context "when fragments are all flat ids" do
      let(:fragments) { [1, 2, 3, 4] }

      it "returns a command to visit all of them in turn" do
        is_expected.to eq("0 1 0 2 0 3 0 4 0 1 0 2 0 3 0 4 0 1 0 2 0")
      end
    end

    context "when fragments contain nested arms" do
      let(:fragments) { [1, [2, 3], 4] }

      it "returns a command to visit all of them in turn" do
        is_expected.to eq("0 1 0 2 3 2 0 4 0 1 0 2 3 2 0 4 0 1 0 2 3")
      end
    end
  end

  describe "#call(money:, connections:, pods:, new_buildings:)" do
    subject(:call) { controller.call(**options) }

    context "when called at test case Example 1" do
      let(:options) do
        {
          money: 2000, connections: [], pods: {}, new_buildings: [
            [0, 0, 80, 60, 30, *[1]*15, *[2]*15],
            %w[1 1 40 30].map(&:to_i),
            %w[2 2 120 30].map(&:to_i)
          ]
        }
      end

      it "returns the command to link to both building 1 and 2 construct a pod looping both" do
        expect(call).to eq("TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2 0")

        expect(controller.buildings).to match(
          0=> hash_including(:type=>0, :x=>80, :y=>60, :astronauts=>{1=>15, 2=>15}),
          1=>hash_including(:type=>1, :x=>40, :y=>30),
          2=>hash_including(:type=>2, :x=>120, :y=>30)
        )
      end
    end

    context "when called at test case Example 2" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>30, :y=>20, :astronauts=>{1=>25, 2=>25}},
          1 => {:type=>1, :x=>130, :y=>20},
          2 => {:type=>2, :x=>130, :y=>70},
        }
      end

      let(:options) { { money: 3000 } }

      it "returns a command to connect the one pad to closest module and start a tram" do
        expect(call).to eq(
          "TUBE 0 1;POD 42 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1"
        )
      end
    end

    context "when called on turn 2 of test case Example 2" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>30, :y=>20, :astronauts=>{1=>25, 2=>25}, :connections=>{:out=>{1=>1}, :in=>{1=>1}}},
          1 => {:type=>1, :x=>130, :y=>20, :connections=>{:in=>{0=>1}, :out=>{0=>1}}},
          2 => {:type=>2, :x=>130, :y=>70},
        }
      end

      let(:options) do
        {
          money: 2100, connections: [{:b_id_1=>0, :b_id_2=>1, :cap=>1}],
          pods: {42 => [20, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]}
        }
      end

      it "returns the tricky command of removing existing underutilized pod and redoing it on both tubes" do
        expect(call).to eq("TUBE 0 2;DESTROY 42;POD 42 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2 0")
      end
    end

    context "when called on turn 4 of test case Example 2, with 2nd pad spawning" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>30, :y=>20, :astronauts=>{1=>25, 2=>25}, :connections=>{:out=>{1=>1, 2=>1}, :in=>{1=>1, 2=>1}}},
          1 => {:type=>1, :x=>130, :y=>20, :connections=>{:in=>{0=>1}, :out=>{0=>1}}},
          2 => {:type=>2, :x=>130, :y=>70, :connections=>{:in=>{0=>1}, :out=>{0=>1}}},
          3 => {:type=>0, :x=>30, :y=>70, :astronauts=>{1=>40, 2=>10}},
        }
      end

      let(:options) do
        {
          money: 3985, connections: [
            {:b_id_1=>0, :b_id_2=>1, :cap=>1},
            {:b_id_1=>0, :b_id_2=>2, :cap=>1}
          ],
          pods: {42 => [21, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0]}
        }
      end

      # TODO, also lay tube from #2 to #1
      it "returns the advanced command of only drawing tube to the visible module #2" do
        expect(call).to eq("TUBE 3 2;POD 43 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2")
      end
    end

    context "when called midway in Example 2 with enough money for a TP" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>30, :y=>20, :astronauts=>{1=>25, 2=>25}, :connections=>{:out=>{1=>1, 2=>1}, :in=>{1=>1, 2=>1}}},
          1 => {:type=>1, :x=>130, :y=>20, :connections=>{:in=>{0=>1}, :out=>{0=>1}}},
          2 => {:type=>2, :x=>130, :y=>70, :connections=>{:in=>{0=>1, 3=>1}, :out=>{0=>1, 3=>1}}},
          3 => {:type=>0, :x=>30, :y=>70, :astronauts=>{1=>40, 2=>10}, :connections=>{:out=>{2=>1}, :in=>{2=>1}}},
        }
      end

      let(:options) do
        {
          money: 5636, connections: [
            {:b_id_1=>3, :b_id_2=>2, :cap=>1},
            {:b_id_1=>0, :b_id_2=>1, :cap=>1},
            {:b_id_1=>0, :b_id_2=>2, :cap=>1}
          ],
          pods: {
            42 => [21, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0],
            43 => [20, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2],
          }
        }
      end

      it "returns the simple fallback command to build a TP" do
        expect(call).to eq("TELEPORT 3 1")
      end
    end

    context "when called on 1st turn of Example 4 (Crater)" do
      let(:buildings) do
        {
          0 => {:type=>2, :x=>80, :y=>75},
          1 => {:type=>0, :x=>80, :y=>15, :astronauts=>{2=>50}},
          2 => {:type=>0, :x=>110, :y=>45, :astronauts=>{1=>50}},
          3 => {:type=>1, :x=>50, :y=>45},
        }
      end

      let(:options) { { money: 5000 } }

      # TODO, may need 2-step connection logic
      it "returns the simple command to connect 2-3 because of type precedence" do
        expect(call).to eq("TUBE 2 3;POD 42 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3")
      end
    end

    context "when called towards the end of Example 4 (Crater)" do
      let(:buildings) do
        {
          0 => {:type=>2, :x=>80, :y=>75, :connections=>{:in=>{1=>0}}},
          1 => {:type=>0, :x=>80, :y=>15, :astronauts=>{2=>50}, :connections=>{:out=>{0=>0}}},
          2 => {:type=>0, :x=>110, :y=>45, :astronauts=>{1=>50}, :connections=>{:out=>{3=>1}, :in=>{3=>1}}},
          3 => {:type=>1, :x=>50, :y=>45, :connections=>{:in=>{2=>1}, :out=>{2=>1}}},
          4 => {:type=>0, :x=>59, :y=>66, :astronauts=>{3=>50}, :connections=>{:out=>{5=>0}}},
          5 => {:type=>3, :x=>101, :y=>24, :connections=>{:in=>{4=>0}}},
          6 => {:type=>4, :x=>101, :y=>66, :connections=>{:in=>{7=>0}}},
          7 => {:type=>0, :x=>59, :y=>24, :astronauts=>{4=>50}, :connections=>{:out=>{6=>0}}},
          8 => {:type=>0, :x=>86, :y=>41, :astronauts=>{1=>25, 2=>25, 3=>25, 4=>25}},
        }
      end

      let(:options) do
        {
          money: 51225, connections: [
            {:b_id_1=>1, :b_id_2=>0, :cap=>0},
            {:b_id_1=>7, :b_id_2=>6, :cap=>0},
            {:b_id_1=>4, :b_id_2=>5, :cap=>0},
            {:b_id_1=>2, :b_id_2=>3, :cap=>1},
          ],
          pods: {
            42 => [20, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3],
          }
        }
      end

      it "returns a simple command to connect to visible modules" do
        expect(call).to eq("TUBE 8 5;TUBE 8 3;POD 43 8 5 8 3 8 5 8 3 8 5 8 3 8 5 8 3 8 5 8 3 8")
      end
    end

    context "when called midway in Example 5 (pairs)" do
      let(:buildings) do
        {
          0 => {:type=>1, :x=>106, :y=>9},
          1 => {:type=>0, :x=>104, :y=>37, :astronauts=>{1=>20}},
          2 => {:type=>2, :x=>148, :y=>10},
          3 => {:type=>0, :x=>47, :y=>13, :astronauts=>{1=>11, 2=>11}},
          4 => {:type=>3, :x=>91, :y=>19},
          5 => {:type=>0, :x=>46, :y=>66, :astronauts=>{1=>8, 2=>8, 3=>8}},
        }
      end

      let(:options) do
        {
          money: 3134, connections: [
            {:b_id_1=>1, :b_id_2=>0, :cap=>1},
            {:b_id_1=>1, :b_id_2=>2, :cap=>1},
            {:b_id_1=>3, :b_id_2=>0, :cap=>1},
          ],
          pods: {
            42 => [20, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
          }
        }
      end

      it "returns a simple command to only link pads to same-color modules" do
        expect(call).to eq(
          # "TUBE 3 2;POD 43 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2"
          "TUBE 1 0;POD 43 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;TUBE 3 0;POD 44 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0"
        )
      end
    end

    context "when called with custom example 2 (two starting pods needed)" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>70, :y=>60, :astronauts=>{1=>2}},
          1 => {:type=>0, :x=>90, :y=>60, :astronauts=>{2=>2}},
          2 => {:type=>1, :x=>40, :y=>30},
          3 => {:type=>2, :x=>120, :y=>30},
        }
      end

      let(:options) { { money: 4000 } }

      it "returns a command to start two pods with unique IDs" do
        expect(call).to eq(
          "TUBE 0 2;POD 42 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2;" \
          "TUBE 1 3;POD 43 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3"
        )
      end
    end

    context "when called with custom example 3 (many starting pods in specific priority)" do
      let(:buildings) do
        {
          0 => {:type=>1, :x=>20, :y=>15},
          1 => {:type=>2, :x=>140, :y=>15},
          2 => {:type=>0, :x=>40, :y=>45, :astronauts=>{1=>40}},
          3 => {:type=>0, :x=>80, :y=>45, :astronauts=>{1=>15, 2=>25}},
          4 => {:type=>0, :x=>120, :y=>45, :astronauts=>{2=>50}},
          5 => {:type=>2, :x=>20, :y=>75},
          6 => {:type=>1, :x=>140, :y=>75},
        }
      end

      let(:options) { { money: 5000 } }

      it "returns a command to connect to closest pad+module pairs" do
        expect(call).to eq(
          "TUBE 4 1;POD 42 4 1 4 1 4 1 4 1 4 1 4 1 4 1 4 1 4 1 4 1;" \
          "TUBE 2 0;POD 43 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0 2 0;" \
          "TUBE 3 5;POD 44 3 5 3 5 3 5 3 5 3 5 3 5 3 5 3 5 3 5 3 5"
        )
      end
    end

    context "when called with Custom Example 4 (pad cluster)" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>5, :y=>30, :astronauts=>{1=>10}},
          1 => {:type=>0, :x=>10, :y=>45, :astronauts=>{1=>5}},
          2 => {:type=>0, :x=>5, :y=>60, :astronauts=>{1=>5}},
          3 => {:type=>1, :x=>150, :y=>45},
        }
      end

      let(:options) { { money: 2600 } }

      it "returns an advanced command to connect closest pad of a cluster to remote module" do
        expect(call).to eq(
          "TUBE 0 3;POD 42 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3 0 3"
          # "TUBE 0 1;" \
          # "TUBE 1 3;" \
          # "POD 42 0 1 3 1 0 1 3 1 0 1 3 1 0 1 3 1 0 1 3 1 0"
        )
      end
    end

    context "when called with example 9 (Expansion)" do
      let(:buildings) do
        {
          0 => {:type=>1, :x=>71, :y=>84, :connections=>{:in=>{2=>1, 3=>1}, :out=>{2=>1, 3=>1}}},
          1 => {:type=>1, :x=>89, :y=>84},
          2 => {:type=>0, :x=>80, :y=>70, :astronauts=>{1=>40}, :connections=>{:out=>{0=>1}, :in=>{0=>1}}},
          3 => {:type=>0, :x=>78, :y=>90, :astronauts=>{1=>40}, :connections=>{:out=>{0=>1}, :in=>{0=>1}}},
          4 => {:type=>1, :x=>70, :y=>69},
          5 => {:type=>1, :x=>91, :y=>70, :connections=>{:in=>{6=>1}, :out=>{6=>1}}},
          6 => {:type=>0, :x=>95, :y=>77, :astronauts=>{1=>40}, :connections=>{:out=>{5=>1}, :in=>{5=>1}}},
          7 => {:type=>2, :x=>86, :y=>61},
          8 => {:type=>1, :x=>62, :y=>71},
          9 => {:type=>3, :x=>63, :y=>90},
          10 => {:type=>2, :x=>74, :y=>61},
          11 => {:type=>0, :x=>60, :y=>82, :astronauts=>{2=>35, 3=>5}},
        }
      end

      let(:options) do
        {
          money: 6009,
          connections: [
            {:b_id_1=>6, :b_id_2=>5, :cap=>1},
            {:b_id_1=>3, :b_id_2=>0, :cap=>1},
            {:b_id_1=>2, :b_id_2=>0, :cap=>1},
          ],
          pods: {
            42 => [20, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0],
            43 => [20, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0],
            44 => [20, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5],
          }
        }
      end

      it "returns a command to connect to closest colors of the new pad" do
        expect(call).to eq(
          "TUBE 11 10;TUBE 11 9;POD 45 11 10 11 9 11 10 11 9 11 10 11 9 11 10 11 9 11 10 11 9 11"
        )
      end
    end

    context "when called midway in Example 9 Expansion" do
      let(:options) do
        {
          money: 8139,
          connections: [
            {:b_id_1=>6, :b_id_2=>5, :cap=>1},
            {:b_id_1=>11, :b_id_2=>10, :cap=>1},
            {:b_id_1=>3, :b_id_2=>0, :cap=>1},
            {:b_id_1=>2, :b_id_2=>0, :cap=>1},
            {:b_id_1=>11, :b_id_2=>9, :cap=>1},
          ],
          pods: {
            42 => [20, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0],
            43 => [20, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0],
            44 => [20, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5],
            45 => [21, 11, 10, 11, 9, 11, 10, 11, 9, 11, 10, 11, 9, 11, 10, 11, 9, 11, 10, 11, 9, 11],
          }
        }
      end

      let(:buildings) do
        {
          0 => {:type=>1, :x=>71, :y=>84, :connections=>{:in=>{2=>1, 3=>1}, :out=>{2=>1, 3=>1}}},
          1 => {:type=>1, :x=>89, :y=>84},
          2 => {:type=>0, :x=>80, :y=>70, :astronauts=>{1=>40}, :connections=>{:out=>{0=>1}, :in=>{0=>1}}},
          3 => {:type=>0, :x=>78, :y=>90, :astronauts=>{1=>40}, :connections=>{:out=>{0=>1}, :in=>{0=>1}}},
          4 => {:type=>1, :x=>70, :y=>69},
          5 => {:type=>1, :x=>91, :y=>70, :connections=>{:in=>{6=>1}, :out=>{6=>1}}},
          6 => {:type=>0, :x=>95, :y=>77, :astronauts=>{1=>40}, :connections=>{:out=>{5=>1}, :in=>{5=>1}}},
          7 => {:type=>2, :x=>86, :y=>61},
          8 => {:type=>1, :x=>62, :y=>71},
          9 => {:type=>3, :x=>63, :y=>90, :connections=>{:in=>{11=>1}, :out=>{11=>1}}},
          10 => {:type=>2, :x=>74, :y=>61, :connections=>{:in=>{11=>1}, :out=>{11=>1}}},
          11 => {:type=>0, :x=>60, :y=>82, :astronauts=>{2=>35, 3=>5}, :connections=>{:out=>{10=>1, 9=>1}, :in=>{10=>1, 9=>1}}},
          12 => {:type=>4, :x=>105, :y=>81},
          13 => {:type=>0, :x=>100, :y=>64, :astronauts=>{2=>32, 3=>8}},
          14 => {:type=>0, :x=>64, :y=>61, :astronauts=>{3=>17, 4=>1, 1=>1, 2=>21}},
        }
      end

      it "returns a command to only link unlinked colors, no repeats" do
        expect(call).to eq (
          "TUBE 13 7;POD 46 13 7 13 7 13 7 13 7 13 7 13 7 13 7 13 7 13 7 13 7;TUBE 14 10;TUBE 14 8;POD 47 14 10 14 8 14 10 14 8 14 10 14 8 14 10 14 8 14 10 14 8 14;TELEPORT 13 9"
        )
        expect(call).to_not include("TUBE 11 7")
      end
    end

    context "when called midway in Example 11 Nested Layers (c)" do
      let(:options) do
        {
          money: 5717,
          connections: [
            {:b_id_1=>15, :b_id_2=>10, :cap=>0},
            {:b_id_1=>36, :b_id_2=>35, :cap=>1},
            {:b_id_1=>27, :b_id_2=>2, :cap=>1},
            {:b_id_1=>21, :b_id_2=>0, :cap=>1},
            {:b_id_1=>27, :b_id_2=>7, :cap=>1},
            {:b_id_1=>15, :b_id_2=>0, :cap=>1},
            {:b_id_1=>27, :b_id_2=>17, :cap=>1},
            {:b_id_1=>3, :b_id_2=>0, :cap=>1},
            {:b_id_1=>15, :b_id_2=>12, :cap=>1},
            {:b_id_1=>3, :b_id_2=>1, :cap=>1},
            {:b_id_1=>27, :b_id_2=>25, :cap=>1},
            {:b_id_1=>21, :b_id_2=>19, :cap=>1},
            {:b_id_1=>34, :b_id_2=>0, :cap=>1},
            {:b_id_1=>3, :b_id_2=>2, :cap=>1},
            {:b_id_1=>34, :b_id_2=>1, :cap=>1},
            {:b_id_1=>36, :b_id_2=>4, :cap=>1},
            {:b_id_1=>3, :b_id_2=>6, :cap=>1},
            {:b_id_1=>15, :b_id_2=>19, :cap=>1},
            {:b_id_1=>27, :b_id_2=>31, :cap=>1},
            {:b_id_1=>36, :b_id_2=>9, :cap=>1},
            {:b_id_1=>3, :b_id_2=>9, :cap=>1},
            {:b_id_1=>36, :b_id_2=>20, :cap=>1},
            {:b_id_1=>36, :b_id_2=>22, :cap=>1},
            {:b_id_1=>24, :b_id_2=>19, :cap=>1},
            {:b_id_1=>38, :b_id_2=>33, :cap=>1},
            {:b_id_1=>34, :b_id_2=>30, :cap=>1},
          ],
          pods: {
            42 => [21, 3, 2, 3, 0, 3, 1, 3, 2, 3, 0, 3, 1, 3, 2, 3, 0, 3, 1, 3, 2, 3],
            43 => [21, 3, 6, 3, 9, 3, 6, 3, 9, 3, 6, 3, 9, 3, 6, 3, 9, 3, 6, 3, 9, 3],
            44 => [21, 15, 12, 15, 19, 15, 0, 15, 12, 15, 19, 15, 0, 15, 12, 15, 19, 15, 0, 15, 12, 15],
            45 => [21, 27, 17, 27, 2, 27, 25, 27, 7, 27, 17, 27, 2, 27, 25, 27, 7, 27, 17, 27, 2, 27],
            46 => [21, 21, 19, 21, 0, 21, 19, 21, 0, 21, 19, 21, 0, 21, 19, 21, 0, 21, 19, 21, 0, 21],
            47 => [20, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19, 24, 19],
            48 => [21, 36, 4, 36, 20, 36, 22, 36, 9, 36, 35, 36, 4, 36, 20, 36, 22, 36, 9, 36, 35, 36],
            49 => [20, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33, 38, 33],
            50 => [21, 34, 1, 34, 0, 34, 30, 34, 1, 34, 0, 34, 30, 34, 1, 34, 0, 34, 30, 34, 1, 34],
          }
        }
      end

      let(:buildings) do
        {
          0 => {:type=>19, :x=>89, :y=>33, :connections=>{:in=>{3=>1, 15=>1, 21=>1, 34=>1}, :out=>{3=>1, 15=>1, 21=>1, 34=>1}}},
          1 => {:type=>20, :x=>94, :y=>39, :connections=>{:in=>{3=>1, 34=>1}, :out=>{3=>1, 34=>1}}},
          2 => {:type=>1, :x=>65, :y=>46, :connections=>{:in=>{3=>1, 27=>1}, :out=>{3=>1, 27=>1}}},
          3 => {:type=>0, :x=>66, :y=>39, :astronauts=>{20=>3, 1=>14, 19=>3}, :connections=>{:out=>{2=>1, 0=>1, 1=>1, 6=>1, 9=>1}, :in=>{2=>1, 0=>1, 1=>1, 6=>1, 9=>1}}},
          4 => {:type=>12, :x=>73, :y=>58, :connections=>{:in=>{36=>1}, :out=>{36=>1}}},
          5 => {:type=>9, :x=>78, :y=>30},
          6 => {:type=>19, :x=>93, :y=>53, :connections=>{:in=>{3=>1}, :out=>{3=>1}}},
          7 => {:type=>7, :x=>66, :y=>50, :connections=>{:in=>{27=>1}, :out=>{27=>1}}},
          8 => {:type=>12, :x=>95, :y=>42},
          9 => {:type=>20, :x=>110, :y=>42, :connections=>{:in=>{3=>1, 36=>1}, :out=>{3=>1, 36=>1}}},
          10 => {:type=>11, :x=>58, :y=>65, :connections=>{:in=>{15=>0}}},
          11 => {:type=>2, :x=>70, :y=>56},
          12 => {:type=>8, :x=>86, :y=>31, :connections=>{:in=>{15=>1}, :out=>{15=>1}}},
          13 => {:type=>11, :x=>67, :y=>53},
          14 => {:type=>4, :x=>76, :y=>60},
          15 => {:type=>0, :x=>75, :y=>31, :astronauts=>{19=>4, 8=>4, 20=>2, 7=>1, 11=>5, 4=>2, 1=>2}, :connections=>{:out=>{12=>1, 19=>1, 0=>1, 10=>0}, :in=>{12=>1, 19=>1, 0=>1}}},
          16 => {:type=>10, :x=>95, :y=>46},
          17 => {:type=>3, :x=>50, :y=>41, :connections=>{:in=>{27=>1}, :out=>{27=>1}}},
          18 => {:type=>13, :x=>109, :y=>53},
          19 => {:type=>11, :x=>71, :y=>16, :connections=>{:in=>{15=>1, 21=>1, 24=>1}, :out=>{15=>1, 21=>1, 24=>1}}},
          20 => {:type=>10, :x=>87, :y=>58, :connections=>{:in=>{36=>1}, :out=>{36=>1}}},
          21 => {:type=>0, :x=>68, :y=>35, :astronauts=>{12=>1, 11=>2, 1=>4, 7=>3, 10=>5, 8=>1, 19=>2, 3=>1, 2=>1}, :connections=>{:out=>{19=>1, 0=>1}, :in=>{19=>1, 0=>1}}},
          22 => {:type=>7, :x=>90, :y=>56, :connections=>{:in=>{36=>1}, :out=>{36=>1}}},
          23 => {:type=>9, :x=>82, :y=>30},
          24 => {:type=>0, :x=>71, :y=>33, :astronauts=>{7=>1, 10=>2, 1=>1, 20=>3, 13=>1, 11=>1, 8=>4, 3=>2, 9=>2, 12=>2, 2=>1}, :connections=>{:out=>{19=>1}, :in=>{19=>1}}},
          25 => {:type=>7, :x=>50, :y=>48, :connections=>{:in=>{27=>1}, :out=>{27=>1}}},
          26 => {:type=>18, :x=>63, :y=>70},
          27 => {:type=>0, :x=>56, :y=>27, :astronauts=>{4=>12, 19=>2, 20=>1, 7=>1, 1=>1, 3=>1, 13=>1, 12=>1}, :connections=>{:out=>{17=>1, 2=>1, 25=>1, 31=>1, 7=>1}, :in=>{17=>1, 2=>1, 25=>1, 31=>1, 7=>1}}},
          28 => {:type=>17, :x=>64, :y=>19},
          29 => {:type=>14, :x=>68, :y=>18},
          30 => {:type=>6, :x=>92, :y=>35, :connections=>{:in=>{34=>1}, :out=>{34=>1}}},
          31 => {:type=>7, :x=>65, :y=>42, :connections=>{:in=>{27=>1}, :out=>{27=>1}}},
          32 => {:type=>16, :x=>94, :y=>50},
          33 => {:type=>9, :x=>108, :y=>57, :connections=>{:in=>{38=>1}, :out=>{38=>1}}},
          34 => {:type=>0, :x=>93, :y=>18, :astronauts=>{18=>2, 6=>2, 16=>2, 13=>2, 20=>4, 4=>2, 10=>1, 17=>1, 19=>2, 7=>1, 12=>1}, :connections=>{:out=>{1=>1, 0=>1, 30=>1}, :in=>{1=>1, 0=>1, 30=>1}}},
          35 => {:type=>17, :x=>53, :y=>59, :connections=>{:in=>{36=>1}, :out=>{36=>1}}},
          36 => {:type=>0, :x=>85, :y=>75, :astronauts=>{8=>1, 12=>4, 9=>1, 10=>2, 7=>2, 18=>1, 11=>1, 14=>1, 17=>3, 20=>4}, :connections=>{:out=>{4=>1, 20=>1, 22=>1, 9=>1, 35=>1}, :in=>{4=>1, 20=>1, 22=>1, 9=>1, 35=>1}}},
          37 => {:type=>9, :x=>61, :y=>21},
          38 => {:type=>0, :x=>92, :y=>72, :astronauts=>{10=>3, 8=>2, 6=>1, 18=>4, 9=>3, 3=>1, 7=>2, 2=>2, 11=>1, 4=>1}, :connections=>{:out=>{33=>1}, :in=>{33=>1}}},
          39 => {:type=>0, :x=>80, :y=>61, :astronauts=>{4=>1, 1=>2, 10=>1, 11=>3, 18=>4, 14=>2, 16=>1, 13=>2, 3=>1, 20=>1, 17=>1, 12=>1}},
          40 => {:type=>2, :x=>84, :y=>59},
          41 => {:type=>0, :x=>108, :y=>35, :astronauts=>{12=>2, 17=>1, 13=>4, 16=>1, 20=>3, 8=>2, 2=>2, 6=>1, 11=>4}},
          42 => {:type=>0, :x=>104, :y=>63, :astronauts=>{3=>1, 10=>1, 18=>7, 19=>2, 14=>1, 9=>1, 4=>1, 16=>3, 20=>1, 1=>1, 13=>1}},
          43 => {:type=>0, :x=>101, :y=>66, :astronauts=>{20=>6, 6=>1, 3=>2, 13=>3, 11=>2, 14=>1, 12=>1, 4=>2, 10=>1, 7=>1}},
          44 => {:type=>0, :x=>109, :y=>38, :astronauts=>{11=>3, 6=>2, 4=>1, 2=>3, 12=>3, 20=>1, 7=>2, 8=>1, 18=>1, 16=>1, 17=>2}},
          45 => {:type=>0, :x=>60, :y=>25, :astronauts=>{3=>2, 6=>4, 1=>2, 17=>2, 20=>4, 19=>1, 13=>2, 16=>1, 7=>1, 8=>1}},
          46 => {:type=>0, :x=>70, :y=>73, :astronauts=>{2=>1, 10=>1, 18=>5, 17=>2, 3=>1, 7=>2, 6=>5, 4=>1, 9=>2}},
          47 => {:type=>7, :x=>51, :y=>52},
          48 => {:type=>13, :x=>74, :y=>74},
          49 => {:type=>0, :x=>49, :y=>44, :astronauts=>{1=>1, 16=>6, 7=>2, 13=>2, 8=>2, 14=>1, 19=>1, 6=>1, 17=>1, 18=>2, 11=>1}},
        }
      end

      it "returns a command to build for pads that aren't maxed at 5 tubes" do
        expect(call).to start_with(
          "TUBE 42 33;POD 51 42 33 42 33 42 33 42 33 42 33 42 33 42 33 42 33 42 33 42 33"
        )
      end
    end

    context "when called at the start of Example 8 (Grid)" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>95, :y=>55, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          1 => {:type=>9, :x=>15, :y=>15},
          2 => {:type=>11, :x=>95, :y=>5},
          3 => {:type=>12, :x=>145, :y=>75},
          4 => {:type=>0, :x=>135, :y=>35, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          5 => {:type=>11, :x=>105, :y=>55},
          6 => {:type=>14, :x=>25, :y=>75},
          7 => {:type=>19, :x=>5, :y=>55},
          8 => {:type=>15, :x=>15, :y=>85},
          9 => {:type=>1, :x=>5, :y=>65},
          10 => {:type=>3, :x=>105, :y=>25},
          11 => {:type=>2, :x=>125, :y=>65},
          12 => {:type=>2, :x=>35, :y=>75},
          13 => {:type=>4, :x=>15, :y=>35},
          14 => {:type=>10, :x=>155, :y=>55},
          15 => {:type=>12, :x=>145, :y=>35},
          16 => {:type=>8, :x=>135, :y=>5},
          17 => {:type=>17, :x=>25, :y=>65},
          18 => {:type=>9, :x=>25, :y=>5},
          19 => {:type=>1, :x=>5, :y=>25},
          20 => {:type=>20, :x=>95, :y=>35},
          21 => {:type=>16, :x=>85, :y=>35},
          22 => {:type=>9, :x=>95, :y=>65},
          23 => {:type=>18, :x=>25, :y=>45},
          24 => {:type=>5, :x=>35, :y=>85},
          25 => {:type=>12, :x=>135, :y=>45},
          26 => {:type=>10, :x=>85, :y=>5},
          27 => {:type=>16, :x=>25, :y=>25},
          28 => {:type=>9, :x=>115, :y=>15},
          29 => {:type=>1, :x=>45, :y=>65},
          30 => {:type=>9, :x=>155, :y=>5},
          31 => {:type=>9, :x=>135, :y=>55},
          32 => {:type=>11, :x=>15, :y=>45},
          33 => {:type=>0, :x=>155, :y=>15, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          34 => {:type=>4, :x=>5, :y=>45},
          35 => {:type=>5, :x=>35, :y=>15},
          36 => {:type=>20, :x=>105, :y=>85},
          37 => {:type=>5, :x=>75, :y=>45},
          38 => {:type=>0, :x=>145, :y=>55, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          39 => {:type=>12, :x=>135, :y=>25},
          40 => {:type=>9, :x=>85, :y=>25},
          41 => {:type=>6, :x=>55, :y=>15},
          42 => {:type=>1, :x=>135, :y=>65},
          43 => {:type=>1, :x=>55, :y=>85},
          44 => {:type=>12, :x=>55, :y=>65},
          45 => {:type=>9, :x=>125, :y=>85},
          46 => {:type=>15, :x=>45, :y=>25},
          47 => {:type=>7, :x=>155, :y=>65},
          48 => {:type=>7, :x=>145, :y=>65},
          49 => {:type=>0, :x=>75, :y=>25, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          50 => {:type=>10, :x=>25, :y=>55},
          51 => {:type=>11, :x=>65, :y=>25},
          52 => {:type=>18, :x=>65, :y=>35},
          53 => {:type=>17, :x=>25, :y=>15},
          54 => {:type=>8, :x=>45, :y=>35},
          55 => {:type=>3, :x=>135, :y=>75},
          56 => {:type=>11, :x=>15, :y=>5},
          57 => {:type=>20, :x=>75, :y=>35},
          58 => {:type=>4, :x=>145, :y=>15},
          59 => {:type=>13, :x=>25, :y=>85},
          60 => {:type=>4, :x=>5, :y=>15},
          61 => {:type=>5, :x=>95, :y=>15},
          62 => {:type=>11, :x=>35, :y=>45},
          63 => {:type=>0, :x=>115, :y=>45, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          64 => {:type=>5, :x=>65, :y=>65},
          65 => {:type=>20, :x=>115, :y=>75},
          66 => {:type=>6, :x=>115, :y=>35},
          67 => {:type=>0, :x=>85, :y=>85, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          68 => {:type=>20, :x=>125, :y=>35},
          69 => {:type=>0, :x=>15, :y=>75, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          70 => {:type=>6, :x=>45, :y=>15},
          71 => {:type=>19, :x=>105, :y=>35},
          72 => {:type=>0, :x=>75, :y=>15, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          73 => {:type=>5, :x=>85, :y=>55},
          74 => {:type=>1, :x=>5, :y=>75},
          75 => {:type=>3, :x=>95, :y=>75},
          76 => {:type=>1, :x=>125, :y=>15},
          77 => {:type=>3, :x=>45, :y=>75},
          78 => {:type=>5, :x=>15, :y=>65},
          79 => {:type=>5, :x=>55, :y=>25},
          80 => {:type=>12, :x=>75, :y=>55},
          81 => {:type=>7, :x=>135, :y=>15},
          82 => {:type=>8, :x=>45, :y=>85},
          83 => {:type=>6, :x=>145, :y=>85},
          84 => {:type=>7, :x=>125, :y=>45},
          85 => {:type=>1, :x=>55, :y=>5},
          86 => {:type=>11, :x=>125, :y=>55},
          87 => {:type=>18, :x=>35, :y=>25},
          88 => {:type=>11, :x=>25, :y=>35},
          89 => {:type=>3, :x=>125, :y=>5},
          90 => {:type=>12, :x=>85, :y=>45},
          91 => {:type=>0, :x=>85, :y=>75, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          92 => {:type=>11, :x=>155, :y=>85},
          93 => {:type=>8, :x=>155, :y=>25},
          94 => {:type=>18, :x=>105, :y=>5},
          95 => {:type=>4, :x=>115, :y=>5},
          96 => {:type=>17, :x=>35, :y=>55},
          97 => {:type=>12, :x=>65, :y=>45},
          98 => {:type=>13, :x=>55, :y=>45},
          99 => {:type=>13, :x=>85, :y=>65},
          100 => {:type=>7, :x=>125, :y=>25},
          101 => {:type=>16, :x=>75, :y=>5},
          102 => {:type=>10, :x=>5, :y=>5},
          103 => {:type=>0, :x=>95, :y=>45, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          104 => {:type=>0, :x=>145, :y=>5, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          105 => {:type=>20, :x=>155, :y=>75},
          106 => {:type=>17, :x=>45, :y=>45},
          107 => {:type=>0, :x=>15, :y=>55, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          108 => {:type=>1, :x=>105, :y=>65},
          109 => {:type=>0, :x=>55, :y=>75, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          110 => {:type=>1, :x=>95, :y=>85},
          111 => {:type=>6, :x=>75, :y=>65},
          112 => {:type=>0, :x=>75, :y=>85, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          113 => {:type=>0, :x=>105, :y=>75, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          114 => {:type=>19, :x=>65, :y=>5},
          115 => {:type=>12, :x=>45, :y=>55},
          116 => {:type=>17, :x=>5, :y=>35},
          117 => {:type=>6, :x=>155, :y=>35},
          118 => {:type=>13, :x=>115, :y=>25},
          119 => {:type=>3, :x=>35, :y=>5},
          120 => {:type=>3, :x=>95, :y=>25},
          121 => {:type=>3, :x=>145, :y=>45},
          122 => {:type=>1, :x=>145, :y=>25},
          123 => {:type=>2, :x=>35, :y=>35},
          124 => {:type=>8, :x=>5, :y=>85},
          125 => {:type=>16, :x=>45, :y=>5},
          126 => {:type=>17, :x=>125, :y=>75},
          127 => {:type=>3, :x=>65, :y=>55},
          128 => {:type=>4, :x=>155, :y=>45},
          129 => {:type=>17, :x=>15, :y=>25},
          130 => {:type=>0, :x=>55, :y=>35, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          131 => {:type=>0, :x=>115, :y=>55, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          132 => {:type=>0, :x=>35, :y=>65, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          133 => {:type=>15, :x=>65, :y=>85},
          134 => {:type=>20, :x=>55, :y=>55},
          135 => {:type=>4, :x=>115, :y=>85},
          136 => {:type=>0, :x=>65, :y=>15, :astronauts=>{1=>2, 2=>2, 3=>2, 4=>2, 5=>2, 6=>2, 7=>2, 8=>2, 9=>2, 10=>2, 11=>2, 12=>2, 13=>2, 14=>2, 15=>2, 16=>2, 17=>2, 18=>2, 19=>2, 20=>2}},
          137 => {:type=>7, :x=>115, :y=>65},
          138 => {:type=>10, :x=>85, :y=>15},
          139 => {:type=>9, :x=>65, :y=>75},
          140 => {:type=>2, :x=>105, :y=>45},
          141 => {:type=>14, :x=>135, :y=>85},
          142 => {:type=>8, :x=>105, :y=>15},
          143 => {:type=>19, :x=>75, :y=>75},
        }
      end

      let(:options) { { money: 100000 } }

      xit "is quick to give a move even if it's not the best" do
        expect(call).to eq("yay")
      end
    end
  end
end
