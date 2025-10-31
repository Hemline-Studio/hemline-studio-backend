class ReplaceClientMeasurementColumns < ActiveRecord::Migration[8.0]
 def up
    # Remove old measurement columns
    remove_column :clients, :ankle, :decimal
    remove_column :clients, :bicep, :decimal
    remove_column :clients, :bottom, :decimal
    remove_column :clients, :chest, :decimal
    remove_column :clients, :head, :decimal
    remove_column :clients, :height, :decimal
    remove_column :clients, :hip, :decimal
    remove_column :clients, :inseam, :decimal
    remove_column :clients, :knee, :decimal
    remove_column :clients, :neck, :decimal
    remove_column :clients, :outseam, :decimal
    remove_column :clients, :shorts, :decimal
    remove_column :clients, :shoulder, :decimal
    remove_column :clients, :sleeve, :decimal
    remove_column :clients, :short_sleeve, :decimal
    remove_column :clients, :thigh, :decimal
    remove_column :clients, :top_length, :decimal
    remove_column :clients, :waist, :decimal
    remove_column :clients, :wrist, :decimal

    # Add new comprehensive measurement columns
    # Upper Body Measurements
    add_column :clients, :shoulder_width, :decimal, precision: 10, scale: 2
    add_column :clients, :bust_chest, :decimal, precision: 10, scale: 2
    add_column :clients, :round_underbust, :decimal, precision: 10, scale: 2
    add_column :clients, :neck_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :armhole_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :arm_length_full, :decimal, precision: 10, scale: 2
    add_column :clients, :arm_length_three_quarter, :decimal, precision: 10, scale: 2
    add_column :clients, :sleeve_length, :decimal, precision: 10, scale: 2
    add_column :clients, :round_sleeve_bicep, :decimal, precision: 10, scale: 2
    add_column :clients, :elbow_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :wrist_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :top_length, :decimal, precision: 10, scale: 2
    add_column :clients, :bust_point_nipple_to_nipple, :decimal, precision: 10, scale: 2
    add_column :clients, :shoulder_to_bust_point, :decimal, precision: 10, scale: 2
    add_column :clients, :shoulder_to_waist, :decimal, precision: 10, scale: 2
    add_column :clients, :round_chest_upper_bust, :decimal, precision: 10, scale: 2
    add_column :clients, :back_width, :decimal, precision: 10, scale: 2
    add_column :clients, :back_length, :decimal, precision: 10, scale: 2
    add_column :clients, :tommy_waist, :decimal, precision: 10, scale: 2

    # Lower Body Measurements
    add_column :clients, :waist, :decimal, precision: 10, scale: 2
    add_column :clients, :high_hip, :decimal, precision: 10, scale: 2
    add_column :clients, :hip_full, :decimal, precision: 10, scale: 2
    add_column :clients, :lap_thigh, :decimal, precision: 10, scale: 2
    add_column :clients, :knee_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :calf_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :ankle_circumference, :decimal, precision: 10, scale: 2
    add_column :clients, :skirt_length, :decimal, precision: 10, scale: 2
    add_column :clients, :trouser_length_outseam, :decimal, precision: 10, scale: 2
    add_column :clients, :inseam, :decimal, precision: 10, scale: 2
    add_column :clients, :crotch_depth, :decimal, precision: 10, scale: 2
    add_column :clients, :waist_to_hip, :decimal, precision: 10, scale: 2
    add_column :clients, :waist_to_floor, :decimal, precision: 10, scale: 2
    add_column :clients, :slit_height, :decimal, precision: 10, scale: 2
    add_column :clients, :bust_apex_to_waist, :decimal, precision: 10, scale: 2
  end

  def down
    # Remove new measurement columns
    remove_column :clients, :shoulder_width, :decimal
    remove_column :clients, :bust_chest, :decimal
    remove_column :clients, :round_underbust, :decimal
    remove_column :clients, :neck_circumference, :decimal
    remove_column :clients, :armhole_circumference, :decimal
    remove_column :clients, :arm_length_full, :decimal
    remove_column :clients, :arm_length_three_quarter, :decimal
    remove_column :clients, :sleeve_length, :decimal
    remove_column :clients, :round_sleeve_bicep, :decimal
    remove_column :clients, :elbow_circumference, :decimal
    remove_column :clients, :wrist_circumference, :decimal
    remove_column :clients, :top_length, :decimal
    remove_column :clients, :bust_point_nipple_to_nipple, :decimal
    remove_column :clients, :shoulder_to_bust_point, :decimal
    remove_column :clients, :shoulder_to_waist, :decimal
    remove_column :clients, :round_chest_upper_bust, :decimal
    remove_column :clients, :back_width, :decimal
    remove_column :clients, :back_length, :decimal
    remove_column :clients, :tommy_waist, :decimal
    remove_column :clients, :waist, :decimal
    remove_column :clients, :high_hip, :decimal
    remove_column :clients, :hip_full, :decimal
    remove_column :clients, :lap_thigh, :decimal
    remove_column :clients, :knee_circumference, :decimal
    remove_column :clients, :calf_circumference, :decimal
    remove_column :clients, :ankle_circumference, :decimal
    remove_column :clients, :skirt_length, :decimal
    remove_column :clients, :trouser_length_outseam, :decimal
    remove_column :clients, :inseam, :decimal
    remove_column :clients, :crotch_depth, :decimal
    remove_column :clients, :waist_to_hip, :decimal
    remove_column :clients, :waist_to_floor, :decimal
    remove_column :clients, :slit_height, :decimal
    remove_column :clients, :bust_apex_to_waist, :decimal

    # Restore old measurement columns
    add_column :clients, :ankle, :decimal, precision: 10, scale: 2
    add_column :clients, :bicep, :decimal, precision: 10, scale: 2
    add_column :clients, :bottom, :decimal, precision: 10, scale: 2
    add_column :clients, :chest, :decimal, precision: 10, scale: 2
    add_column :clients, :head, :decimal, precision: 10, scale: 2
    add_column :clients, :height, :decimal, precision: 10, scale: 2
    add_column :clients, :hip, :decimal, precision: 10, scale: 2
    add_column :clients, :inseam, :decimal, precision: 10, scale: 2
    add_column :clients, :knee, :decimal, precision: 10, scale: 2
    add_column :clients, :neck, :decimal, precision: 10, scale: 2
    add_column :clients, :outseam, :decimal, precision: 10, scale: 2
    add_column :clients, :shorts, :decimal, precision: 10, scale: 2
    add_column :clients, :shoulder, :decimal, precision: 10, scale: 2
    add_column :clients, :sleeve, :decimal, precision: 10, scale: 2
    add_column :clients, :short_sleeve, :decimal, precision: 10, scale: 2
    add_column :clients, :thigh, :decimal, precision: 10, scale: 2
    add_column :clients, :top_length, :decimal, precision: 10, scale: 2
    add_column :clients, :waist, :decimal, precision: 10, scale: 2
    add_column :clients, :wrist, :decimal, precision: 10, scale: 2
  end
end
