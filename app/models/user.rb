class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :role_users, dependent: :destroy
  has_many :roles, through: :role_users
  has_many :permissions, dependent: :destroy
  has_and_belongs_to_many :groups

  validates :name, presence: true

  def admin?
    roles.exists?(name: "admin")
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
