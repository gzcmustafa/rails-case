class Product < ApplicationRecord
    validates :name, presence: true
    validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  end
  