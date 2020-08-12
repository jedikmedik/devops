# frozen_string_literal: true

# == Schema Information
#
# Table name: pastes
#
#  id                 :integer          not null, primary key
#  body               :text
#  request_info       :text
#  permalink          :text
#  language           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  auto_destroy       :boolean          default(FALSE), not null
#  will_be_deleted_at :datetime
#
# Indexes
#
#  index_pastes_on_permalink  (permalink) UNIQUE
#

class Paste < ApplicationRecord
  extend Enumerize
  enumerize :language, in: [:text, :markdown], default: :text

  store :request_info, accessors: [:ip, :request, :referer]

  # временно отключили
  # acts_as_paranoid

  before_create :generate_permalink
  before_validation :strip_body

  validates_presence_of :body
  validates_length_of :body, maximum: 512 * 1024

  def to_param
    permalink
  end

  def ttl_days
    ((will_be_deleted_at - Time.now) / (60 * 60 * 24)).round
  end

  def ttl_days=(days)
    self.will_be_deleted_at = days.to_i <= 5000 ? days.to_i.days.from_now : 5000.days.from_now
  end

  private

  def generate_permalink
    permalink = nil
    loop do
      permalink = SecureRandom.hex
      break unless Paste.exists?(permalink: permalink)
    end
    self.permalink = permalink
  end

  def strip_body
    self.body = body.strip if body.present?
  end
end
