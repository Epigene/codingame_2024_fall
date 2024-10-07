RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new(buildings: buildings) }
  let(:buildings) { {} }

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

    context "when called with custom example 4 (pad cluster)" do
      let(:buildings) do
        {
          0 => {:type=>0, :x=>70, :y=>30, :astronauts=>{1=>10}},
          1 => {:type=>0, :x=>90, :y=>45, :astronauts=>{1=>5}},
          2 => {:type=>0, :x=>70, :y=>60, :astronauts=>{1=>5}},
          3 => {:type=>1, :x=>150, :y=>45},
        }
      end

      let(:options) { { money: 2500 } }

      it "returns an advanced command to connect closest pad of a cluster to remote module" do
        expect(call).to eq(
          "TUBE 1 4;" \
          "TUBE 1 0;" \
          "TUBE 1 2;POD 42 1 0 1 4 1 2 1 4 1 0 1 4 1 2 1 4"
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
