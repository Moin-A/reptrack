class Ability
  include ActiveModel::Model
  include CanCan::Ability

  def initialize(user)

    if user.present?
      entities = [Account, Address];

      can :manage, Task, user_id: user.id
      can :manage, Task, assignee_id: user.id

      can :manage, User, id: user.id
      can :manage, entities, access: 'Public'
      can :manage, entities, assignee_id: user.id
      can :manage, entities, user_id: user.id
      
      if user.admin?
        can :manage, entities
      else
        can :read, entities
      end
    end
  end
end
