RSpec.describe Point, instance_name: :point do
  let(:point) { described_class[0, 0] }

  describe "#on_segment?(p1, p2)" do
    subject(:on_segment?) { point.on_segment?(p1, p2) }

    let(:p1) { described_class[0, 0] }
    let(:p2) { described_class[10, 10] }

    context "when point on one of ends" do
      let(:point) { described_class[0, 0] }

      it { is_expected.to be(true) }
    end

    context "when point somewhere in the middle of segment" do
      let(:point) { described_class[5, 5] }

      it { is_expected.to be(true) }
    end

    context "when point just past p2" do
      let(:point) { described_class[11, 11] }

      it { is_expected.to be(false) }
    end

    context "when point above segment" do
      let(:point) { described_class[2, 3] }

      it { is_expected.to be(false) }
    end
  end
end
