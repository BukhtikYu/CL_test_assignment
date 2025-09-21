# == Schema Information
#
# Table name: permitted_routes
#
#  id                   :bigint           not null, primary key
#  carrier              :string           not null
#  origin_iata          :string           not null
#  destination_iata     :string           not null
#  direct               :boolean          default(true), not null
#  transfer_iata_codes  :text             default([]), not null, is an Array
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

class PermittedRoute < ApplicationRecord
  validates :carrier, :origin_iata, :destination_iata, presence: true

  scope :for_trip, ->(carrier:, origin:, destination:) {
    where(carrier: carrier, origin_iata: origin, destination_iata: destination)
  }
  scope :direct, -> { where(direct: true) }
  scope :with_transfer, -> { where(direct: false) }
end