require File.expand_path(File.join(File.dirname(__FILE__), '..', 'proxysql'))

Puppet::Type.type(:proxy_mysql_user).provide(:proxysql, parent: Puppet::Provider::Proxysql) do
  desc 'Manage users for a ProxySQL instance.'
  commands mysql: 'mysql'

  # Build a property_hash containing all the discovered information about MySQL
  # users.
  def self.instances
    users = mysql([defaults_file, '-NBe',
                   'SELECT username FROM mysql_users'].compact).split("\n")

    # To reduce the number of calls to MySQL we collect all the properties in
    # one big swoop.
    users.map do |name|
      query = "SELECT password, active, use_ssl, default_hostgroup, default_schema, schema_locked, transaction_persistent, fast_forward, backend, frontend, max_connections FROM mysql_users WHERE username = '#{name}'"

      @password, @active, @use_ssl, @default_hostgroup, @default_schema,
      @schema_locked, @transaction_persistent, @fast_forward, @backend, @frontend,
      @max_connections = mysql([defaults_file, '-NBe', query].compact).split(%r{\s})

      new(name: name,
          ensure: :present,
          password: @password,
          active: @active,
          use_ssl: @use_ssl,
          default_hostgroup: @default_hostgroup,
          default_schema: @default_schema,
          schema_locked: @schema_locked,
          transaction_persistent: @transaction_persistent,
          fast_forward: @fast_forward,
          backend: @backend,
          frontend: @frontend,
          max_connections: @max_connections)
    end
  end

  # We iterate over each proxy_mysql_user entry in the catalog and compare it against
  # the contents of the property_hash generated by self.instances
  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
      if provider = users.find { |user| user.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    name                   = @resource[:name]
    password               = @resource.value(:password)
    active                 = @resource.value(:active) || 1
    use_ssl                = @resource.value(:use_ssl) || 0
    default_hostgroup      = @resource.value(:default_hostgroup) || 0
    default_schema         = @resource.value(:default_schema) || ''
    schema_locked          = @resource.value(:schema_locked) || 0
    transaction_persistent = @resource.value(:transaction_persistent) || 0
    fast_forward           = @resource.value(:fast_forward) || 0
    backend                = @resource.value(:backend) || 1
    frontend               = @resource.value(:frontend) || 1
    max_connections        = @resource.value(:max_connections) || 10_000

    query = 'INSERT INTO mysql_users (`username`, `password`, `active`, `use_ssl`, `default_hostgroup`, `default_schema`, '
    query << ' `schema_locked`, `transaction_persistent`, `fast_forward`, `backend`, `frontend`, `max_connections`) '
    query << " VALUES ('#{name}', '#{password}', #{active}, #{use_ssl}, #{default_hostgroup}, '#{default_schema}', "
    query << " #{schema_locked}, #{transaction_persistent}, #{fast_forward}, #{backend}, #{frontend}, #{max_connections})"
    mysql([defaults_file, '-e', query].compact)
    @property_hash[:ensure] = :present

    exists? ? (return true) : (return false)
  end

  def destroy
    name = @resource[:name]
    mysql([defaults_file, '-e', "DELETE FROM mysql_users WHERE username = '#{name}'"].compact)

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def flush
    update_user(@property_flush) if @property_flush
    @property_hash.clear

    load_to_runtime = @resource[:load_to_runtime]
    if load_to_runtime == :true
      mysql([defaults_file, '-NBe', 'LOAD MYSQL USERS TO RUNTIME'].compact)
    end

    save_to_disk = @resource[:save_to_disk]
    if save_to_disk == :true
      mysql([defaults_file, '-NBe', 'SAVE MYSQL USERS TO DISK'].compact)
    end
  end

  def update_user(properties)
    name = @resource[:name]

    return false if properties.empty?

    values = []
    properties.each do |field, value|
      values.push("`#{field}` = '#{value}'")
    end
    query = 'UPDATE mysql_users SET '
    query << values.join(', ')
    query << " WHERE username = '#{name}'"

    mysql([defaults_file, '-e', query].compact)
  end

  # Generates method for all properties of the property_hash
  mk_resource_methods

  def password=(value)
    @property_flush[:password] = value
  end

  def active=(value)
    @property_flush[:active] = value
  end

  def use_ssl=(value)
    @property_flush[:use_ssl] = value
  end

  def default_hostgroup=(value)
    @property_flush[:default_hostgroup] = value
  end

  def default_schema=(value)
    @property_flush[:default_schema] = value
  end

  def schema_locked=(value)
    @property_flush[:schema_locked] = value
  end

  def transaction_persistent=(value)
    @property_flush[:transaction_persistent] = value
  end

  def fast_forward=(value)
    @property_flush[:fast_forward] = value
  end

  def backend=(value)
    @property_flush[:backend] = value
  end

  def frontend=(value)
    @property_flush[:frontend] = value
  end

  def max_connections=(value)
    @property_flush[:max_connections] = value
  end
end
