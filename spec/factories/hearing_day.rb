# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_day do
    hearing_date { Date.new(2019, 3, 2) }
    hearing_type { "C" }
    room { "2" }
    created_by { create(:user).css_id }
    updated_by { create(:user).css_id }
  end
end
