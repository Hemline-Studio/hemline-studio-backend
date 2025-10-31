# == Schema Information
#
# Table name: clients
#
# Standard Columns:
#  id                    :uuid            not null, primary key
#  first_name                  :string          not null
#  last_name                  :string          not null
#  gender                :string          not null (Male/Female)
#  email                 :string
#  phone_number          :string
#  measurement_unit      :string          not null (inches/centimeters)
#  in_trash              :boolean         default(false)
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#  user_id               :uuid            not null (foreign key)
#
# Upper Body Measurements (stored in centimeters):
#  shoulder_width                :decimal(10,2)  # Distance across shoulders
#  bust_chest                    :decimal(10,2)  # Fullest part of bust/chest
#  round_underbust               :decimal(10,2)  # Measurement under the bust
#  neck_circumference            :decimal(10,2)  # Around the neck
#  armhole_circumference         :decimal(10,2)  # Around the armhole
#  arm_length_full               :decimal(10,2)  # Full arm length
#  arm_length_three_quarter      :decimal(10,2)  # Three-quarter sleeve length
#  sleeve_length                 :decimal(10,2)  # Standard sleeve length
#  round_sleeve_bicep            :decimal(10,2)  # Around the bicep/sleeve
#  elbow_circumference           :decimal(10,2)  # Around the elbow
#  wrist_circumference           :decimal(10,2)  # Around the wrist
#  top_length                    :decimal(10,2)  # Length of top/blouse
#  bust_point_nipple_to_nipple   :decimal(10,2)  # Distance between bust points
#  shoulder_to_bust_point        :decimal(10,2)  # Shoulder to bust point
#  shoulder_to_waist             :decimal(10,2)  # Shoulder to waist length
#  round_chest_upper_bust        :decimal(10,2)  # Upper bust measurement
#  back_width                    :decimal(10,2)  # Width across back
#  back_length                   :decimal(10,2)  # Length of back
#  tommy_waist                   :decimal(10,2)  # Tommy/waist measurement
#
# Lower Body Measurements (stored in centimeters):
#  waist                         :decimal(10,2)  # Natural waistline
#  high_hip                      :decimal(10,2)  # High hip measurement
#  hip_full                      :decimal(10,2)  # Fullest part of hip
#  lap_thigh                     :decimal(10,2)  # Thigh/lap measurement
#  knee_circumference            :decimal(10,2)  # Around the knee
#  calf_circumference            :decimal(10,2)  # Around the calf
#  ankle_circumference           :decimal(10,2)  # Around the ankle
#  skirt_length                  :decimal(10,2)  # Desired skirt length
#  trouser_length_outseam        :decimal(10,2)  # Trouser outseam length
#  inseam                        :decimal(10,2)  # Inner leg measurement
#  crotch_depth                  :decimal(10,2)  # Waist to crotch depth
#  waist_to_hip                  :decimal(10,2)  # Waist to hip distance
#  waist_to_floor                :decimal(10,2)  # Waist to floor length
#  slit_height                   :decimal(10,2)  # Height of garment slit
#  bust_apex_to_waist            :decimal(10,2)  # Bust apex to waist
#
# Associations:
#  belongs_to :user
#  has_many :client_custom_field_values, dependent: :destroy
#  has_many :custom_fields, through: :client_custom_field_values
#
# Association Diagram:
#
#  User ──┐
#         │
#         │ has_many
#         ├──────────> Client (this model)
#         │                 │
#         │                 │ has_many
#         │                 └──────────> ClientCustomFieldValue (join table)
#         │                                      │
#         │ has_many                             │ belongs_to
#         └──────────> CustomField <─────────────┘
#                           ▲
#                           │ has_many :through
#                           └─ Client can access custom_fields through client_custom_field_values
#
# Notes:
#  - All measurements are stored in centimeters in the database
#  - Conversions to inches happen via display_measurements method
#  - The measurement_unit field tracks the user's preferred display unit
#  - Custom fields allow dynamic addition of user-defined measurements
#  - The has_many :through relationship allows storing custom field values per client
#

class Client < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :client_custom_field_values, dependent: :destroy
  has_many :custom_fields, through: :client_custom_field_values

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :gender, presence: true, inclusion: { in: %w[Male Female] }
  validates :measurement_unit, presence: true, inclusion: { in: %w[inches centimeters] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, length: { maximum: 20 }, allow_blank: true

  # Validate measurement values are positive when present
  measurement_fields.each do |measurement|
    validates measurement.to_sym, numericality: { greater_than: 0 }, allow_blank: true
  end

  # Scopes
  scope :active, -> { where(in_trash: false) }
  scope :trashed, -> { where(in_trash: true) }
  scope :male, -> { where(gender: "Male") }
  scope :female, -> { where(gender: "Female") }

  # Callbacks
  before_validation :set_defaults
  before_save :convert_measurements_to_cm

  # Class methods
  def self.bulk_soft_delete(client_ids)
    where(id: client_ids).update_all(in_trash: true, updated_at: Time.current)
  end

  def self.measurement_fields
    %w[
      shoulder_width bust_chest round_underbust neck_circumference armhole_circumference
      arm_length_full arm_length_three_quarter sleeve_length round_sleeve_bicep
      elbow_circumference wrist_circumference top_length bust_point_nipple_to_nipple
      shoulder_to_bust_point shoulder_to_waist round_chest_upper_bust back_width
      back_length tommy_waist waist high_hip hip_full lap_thigh knee_circumference
      calf_circumference ankle_circumference skirt_length trouser_length_outseam
      inseam crotch_depth waist_to_hip waist_to_floor slit_height bust_apex_to_waist
    ]
  end

  # Instance methods
  def soft_delete!
    update!(in_trash: true)
  end

  def restore!
    update!(in_trash: false)
  end

  def custom_field_value(custom_field)
    client_custom_field_values.find_by(custom_field: custom_field)&.value
  end

  def set_custom_field_value(custom_field, value)
    ccfv = client_custom_field_values.find_or_initialize_by(custom_field: custom_field)
    ccfv.value = value
    ccfv.save!
  end

  def display_measurements
    measurements = {}
    self.class.measurement_fields.each do |field|
      value = send(field)
      next unless value

      measurements[field] = measurement_unit == "inches" ? cm_to_inches(value) : value
    end
    measurements
  end

  private

  def set_defaults
    self.in_trash = false if in_trash.nil?
    self.measurement_unit ||= "centimeters"
  end

  def convert_measurements_to_cm
    return unless measurement_unit == "inches"

    self.class.measurement_fields.each do |field|
      value = public_send(field)
      next unless value && public_send("#{field}_changed?")
      public_send("#{field}=", inches_to_cm(value))
    end
  end

  def inches_to_cm(inches)
    inches * 2.54
  end

  def cm_to_inches(cm)
    cm / 2.54
  end
end
