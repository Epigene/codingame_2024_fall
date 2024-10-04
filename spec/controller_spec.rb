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
        expect(call).to eq("TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2 0 1 0 2")

        expect(controller.buildings).to eq(
          0=>{:type=>0, :x=>80, :y=>60, :astronauts=>{1=>15, 2=>15}},
          1=>{:type=>1, :x=>40, :y=>30},
          2=>{:type=>2, :x=>120, :y=>30}
        )
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
          "TUBE 3 2;POD 43 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2 3 2;TUBE 5 0;TUBE 5 2;TUBE 5 4;" \
          "POD 43 5 0 5 2 5 4 5 0 5 2 5 4 5 0 5 2 5 4"
        )
      end
    end
  end
end
