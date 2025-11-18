class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_create :ensure_uuid

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
