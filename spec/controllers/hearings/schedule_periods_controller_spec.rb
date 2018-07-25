RSpec.describe Hearings::SchedulePeriodsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Build HearSched"]) }
  let!(:ro_schedule_period) { create(:ro_schedule_period) }
  let!(:judge_schedule_period) { create(:judge_schedule_period) }

  context "index" do
    it "returns all schedule periods" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["schedule_periods"].size).to eq 2
    end
  end

  context "show" do
    it "returns a schedule period and its hearing days" do
      get :show, params: { schedule_period_id: ro_schedule_period.id }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["schedule_period"]["hearing_days"].count).to eq 3
      expect(response_body["schedule_period"]["file_name"]).to eq "validRoSpreadsheet.xlsx"
      expect(response_body["schedule_period"]["start_date"]).to eq "2018-01-01"
      expect(response_body["schedule_period"]["end_date"]).to eq "2018-06-01"
    end
  end

  context "create" do
    it "creates a new schedule period" do
      id = SchedulePeriod.last.id + 1
      base64_header = "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,"
      post :create, params: {
        schedule_period: {
          type: "RoSchedulePeriod",
          start_date: "2015/10/24",
          end_date: "2016/10/24",
          file_name: "fakeFileName.xlsx"
        },
        file: base64_header + Base64.encode64(File.open("spec/support/validRoSpreadsheet.xlsx").read)
      }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq id
    end
  end

  context "persist full schedule for a schedule period" do
    it "persists a schedule for a given schedulePeriod id" do
      put :update, params: {
        schedule_period_id: ro_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq ro_schedule_period.id

      # Invoking separate controller to verify that we persisted
      # the schedule for the given date range.
      @controller = Hearings::HearingDayController.new
      get :index, params: { start_date: "2018-01-01", end_date: "2018-06-01" }, as: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to be_between(355, 359)
    end
  end

  context "assign judges to full schedule for a schedule period" do
    it "update judge assignments for a given schedulePeriod id" do
      put :update, params: {
        schedule_period_id: judge_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq judge_schedule_period.id
    end
  end
end
