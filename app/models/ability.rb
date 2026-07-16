class Ability
  include ActiveModel::Model
  include CanCan::Ability

  def initialize(user)
    if user.present?
      entities = [ Account, Address, Lead, Group, Opportunity ]

      can :manage, Task, user_id: user.id
      can :manage, Task, assignee_id: user.id

      can :manage, User, id: user.id
      can :manage, entities, access: "Public"
      can :manage, entities, assignee_id: user.id
      can :manage, entities, user_id: user.id

      # Campaign posts have no access/assignee_id columns, so they can't share the
      # CRM entity rules above. Owner is assigned in the controller on create.
      can :create, Campaign::Post
      can %i[read update destroy], Campaign::Post, user_id: user.id

      if user.admin?
        can :manage, entities
        can :manage, Campaign::Post
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
