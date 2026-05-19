class RoleConfiguration
  class Role
    attr_accessor :name, :permissionsSets
    def initialize(name)
      @name = name
      @permissionsSets = Set.new
    end
  end

  def initialize
    @role = Hash.new do |hash, name|
      hash[name] = Role.new(name)
    end
  end

  def assign_permissions(name, permission_sets)
    @role[name.to_sym].permissionsSets.merge(permission_sets)
  end

  def activate_permissions(ability, user)
    roles = [ "default" ]
    roles += user.roles.map(&:name) if user

    applicable_permissions = Set.new
    roles.each { |role_name| applicable_permissions |= @role[role_name.to_sym].permissionsSets }

    applicable_permissions.each { |permission_set_class| permission_set_class.new(ability).activate! }
  end
end
