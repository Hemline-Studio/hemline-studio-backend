FactoryBot.define do
  factory :client do
    association :user
    sequence(:name) { |n| "Client #{n}" }
    gender { [ "Male", "Female" ].sample }
    measurement_unit { [ "inches", "centimeters" ].sample }
    sequence(:email) { |n| "client#{n}@example.com" }
    phone_number { "+1234567890" }
    in_trash { false }

    # Add some measurement data
    chest { 40.0 }
    waist { 32.0 }
    height { 70.0 }

    trait :male do
      gender { "Male" }
    end

    trait :female do
      gender { "Female" }
    end

    trait :in_inches do
      measurement_unit { "inches" }
    end

    trait :in_centimeters do
      measurement_unit { "centimeters" }
    end

    trait :trashed do
      in_trash { true }
    end
  end
end
