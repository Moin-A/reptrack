class Ability
  include ActiveModel::Model
  include CanCan::Ability

  def initialize(user)

    if user.present?
      entities = [Account, Address]

      can :manage, User, id: user.id
      if user.admin?
        can :manage, entities
      else
        can :read, entities
      end
    end
  end
end
