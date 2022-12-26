FactoryBot.define do
  factory :user do
    first_name { "Hanna" }
    last_name { "Lohmann"}
    email { "hannalohmann@icloud.com" }
    password { '123455'}
    password_confirmation { '123455'}
  end
end
