class Ability
  include ActiveModel::Model
  include CanCan::Ability

  def initialize(user)

    if user.present?
      entities = [Account, Address, Lead]

      can :manage, Task, user_id: user.id
      can :manage, Task, assignee_id: user.id

      can :manage, User, id: user.id
      can :manage, entities, access: 'Public'
      can :manage, entities, assignee_id: user.id
      can :manage, entities, user_id: user.id
      
      if user.admin?
        can :manage, entities
      else
        permissions = Permission.arel_table

        scope = permissions[:user_id].eq(user.id).or(permissions[:group_id].in(user.group_ids))

        Permission.where(scope).each do |p|
          next if p.asset_type.nil? || p.asset_id.nil?
          can :manage, p.asset_type.constantize, id: p.asset_id
        end
      end
    end
  end
end
