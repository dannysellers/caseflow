require "rails_helper"

RSpec.feature "Edit issues" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:test_facols)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:receipt_date) { Time.zone.today - 20 }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date + 1.day,
      profile_date: receipt_date + 4.days,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  context "Higher Level Reviews" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "abc123",
        rating_issue_profile_date: rating.profile_date,
        review_request: higher_level_review,
        description: "Left knee granted"
      )
    end

    before do
      higher_level_review.create_issues!([request_issue])
      higher_level_review.process_end_product_establishments!
    end

    it "shows selected issues" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(find_field("Left knee granted", visible: false)).to be_checked
    end

    feature "cancel edits" do
      def click_cancel(visit_page)
        visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit#{visit_page}"
        click_on "Cancel edit"
        correct_path = "/higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/cancel"
        expect(page).to have_current_path(correct_path)
        expect(page).to have_content("Claim Edit Cancelled")
      end

      scenario "from landing page" do
        click_cancel("/")
      end

      scenario "from select_issues page" do
        click_cancel("/select_issues")
      end
    end
  end

  context "Supplemental claims" do
    let!(:supplemental_claim) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "abc123",
        rating_issue_profile_date: rating.profile_date,
        review_request: supplemental_claim,
        description: "Left knee granted"
      )
    end

    before do
      supplemental_claim.create_issues!([request_issue])
      supplemental_claim.process_end_product_establishments!
    end

    it "shows selected issues" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(find_field("Left knee granted", visible: false)).to be_checked
    end
  end
end
