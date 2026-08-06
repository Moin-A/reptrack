class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # The workspace this user belongs to (one person, one workspace). Nullable —
  # set after the user pays to create their workspace. Users are public; this is
  # what separates them per workspace (roles/permissions stay tenant-scoped).
  belongs_to :workspace, optional: true

  has_many :role_users, dependent: :destroy
  has_many :roles, through: :role_users
  has_many :permissions, dependent: :destroy
  # join_table pinned explicitly: User is an Apartment excluded_model, so its
  # table_name is "public.users" and the HABTM default would derive the broken
  # join table "groups_public.users".
  has_and_belongs_to_many :groups, join_table: "groups_users"

  validates :name, presence: true

  def admin?
    roles.exists?(name: "admin")
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
