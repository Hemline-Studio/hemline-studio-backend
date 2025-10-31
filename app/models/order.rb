# == Schema Information
#
# Table name: orders
#
#  id           :uuid            not null, primary key
#  client_id    :uuid            not null (foreign key)
#  user_id      :uuid            not null (foreign key)
#  item         :string          not null
#  quantity     :integer         not null, default: 1
#  notes        :text
#  is_done      :boolean         default(false), not null
#  due_date     :datetime
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#
# Associations:
#  belongs_to :client
#  belongs_to :user
#
# Association Diagram:
#
#  User ──┐
#         │
#         │ has_many
#         ├──────────> Client
#         │                 │
#         │                 │ has_many
#         │                 └──────────> Order (this model)
#         │                                  │
#         │ has_many                         │ belongs_to
#         └──────────────────────────────────┘
#
# Notes:
#  - Orders belong to both a client and a user for efficient querying
#  - quantity must be at least 1
#  - is_done tracks order completion status
#  - due_date is optional

class Order < ApplicationRecord
  # Associations
  belongs_to :client
  belongs_to :user

  # Validations
  validates :item, presence: true, length: { minimum: 1, maximum: 255 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :notes, length: { maximum: 1000 }, allow_blank: true
  validates :is_done, inclusion: { in: [ true, false ] }

  # Scopes
  scope :pending, -> { where(is_done: false) }
  scope :completed, -> { where(is_done: true) }
  scope :overdue, -> { where("due_date < ? AND is_done = ?", Time.current, false) }
  scope :upcoming, -> { where("due_date >= ? AND is_done = ?", Time.current, false) }
  scope :ordered_by_due_date, -> { order(Arel.sql("CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, due_date ASC")) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.bulk_mark_done(order_ids)
    where(id: order_ids).update_all(is_done: true, updated_at: Time.current)
  end

  def self.bulk_delete(order_ids)
    where(id: order_ids).destroy_all
  end

  # Instance methods
  def mark_done!
    update!(is_done: true)
  end

  def mark_pending!
    update!(is_done: false)
  end

  def overdue?
    due_date.present? && due_date < Time.current && !is_done
  end

  def client_name
    return nil if client.first_name.blank? && client.last_name.blank?
    [ client.first_name, client.last_name ].compact.join(" ").strip
  end
end
