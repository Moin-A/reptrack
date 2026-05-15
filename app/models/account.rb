class Account < ApplicationRecord
   validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/, message: "the email format is not valid" } 
end
