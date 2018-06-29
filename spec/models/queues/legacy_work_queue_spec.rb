describe WorkQueue do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".tasks_with_appeals" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end

    subject { LegacyWorkQueue.tasks_with_appeals(user, role) }

    context "when it is an attorney" do
      let(:role) { "Attorney" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(AttorneyLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end

    context "when it is a judge" do
      let(:role) { "Judge" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(JudgeLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end
  end
end