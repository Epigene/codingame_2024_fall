RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new(buildings: buildings) }
  let(:buildings) { [] }

  describe "#call(money:, travel_routes:, pods:, new_buildings:)" do
    subject(:call) { controller.call(**options) }

    context "when called at test case Example 1" do
      let(:options) do
        {
          money: 2000, travel_routes: [], pods: {}, new_buildings: [
            %w[0 0 80 60 30 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2].map(&:to_i),
            %w[1 1 40 30].map(&:to_i),
            %w[2 2 120 30].map(&:to_i)
          ]
        }
      end

      it "returns the command to link to both building 1 and 2 construct a pod looping both" do
        expect(call).to eq("TUBE 0 1;TUBE 0 2;POD 42 0 1 0 2")

        expect(controller.buildings).to eq(
          [

          ]
        )
      end
    end
  end
end
