class QualityReview < Organization
  def self.singleton
    QualityReview.first || QualityReview.create(name: "Quality Review", url: "quality-review")
  end
end
