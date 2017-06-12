require File.expand_path(File.join(File.dirname(__FILE__), '..', 'proxysql'))
Puppet::Type.type(:proxy_scheduler).provide(:proxysql, parent: Puppet::Provider::Proxysql) do
  desc 'Manage scheduler entry for a ProxySQL instance.'
  commands mysql: 'mysql'

  # Build a property_hash containing all the discovered information about query rules.
  def self.instances
    instances = []
    schedulers = mysql([defaults_file, '-NBe',
                        'SELECT `id` FROM `scheduler`'].compact).split(%r{\n})

    schedulers.map do |scheduler_id|
      query = 'SELECT `active`, `interval_ms`, `filename`, '
      query << '`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `comment` '
      query << "FROM `scheduler` WHERE `id` = #{scheduler_id}"

      @active, @interval_ms, @filename, @arg1, @arg2, @arg3, @arg4, @arg5,
      @comment = mysql([defaults_file, '-NBe', query].compact).delete(%r{\n}).split(%r{\t})
      name = "scheduler-#{scheduler_id}"

      instances << new(
        name: name,
        ensure: :present,
        scheduler_id: scheduler_id,
        active: @active,
        interval_ms: @interval_ms,
        filename: @filename,
        arg1: @arg1,
        arg2: @arg2,
        arg3: @arg3,
        arg4: @arg4,
        arg5: @arg5,
        comment: @comment
      )
    end
    instances
  end

  # We iterate over each proxy_scheduler entry in the catalog and compare it against
  # the contents of the property_hash generated by self.instances
  def self.prefetch(resources)
    schedulers = instances
    resources.keys.each do |name|
      provider = schedulers.find { |scheduler| scheduler.name == name }
      resources[name].provider = provider if provider
    end
  end

  def create
    _name = @resource[:name]
    scheduler_id = make_sql_value(@resource.value(:scheduler_id))
    active = make_sql_value(@resource.value(:active) || 1)
    interval_ms = make_sql_value(@resource.value(:interval_ms) || 10_000)
    filename = make_sql_value(@resource.value(:filename))
    arg1 = make_sql_value(@resource.value(:arg1) || nil)
    arg2 = make_sql_value(@resource.value(:arg2) || nil)
    arg3 = make_sql_value(@resource.value(:arg3) || nil)
    arg4 = make_sql_value(@resource.value(:arg4) || nil)
    arg5 = make_sql_value(@resource.value(:arg5) || nil)
    comment = make_sql_value(@resource.value(:comment) || '')

    query = 'INSERT INTO `scheduler` (`id`, `active`, `interval_ms`, `filename`, '
    query << '`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `comment`) VALUES ('
    query << "#{scheduler_id}, #{active}, #{interval_ms}, #{filename}, "
    query << "#{arg1}, #{arg2}, #{arg3}, #{arg4}, #{arg5}, #{comment})"
    mysql([defaults_file, '-e', query].compact)
    @property_hash[:ensure] = :present

    exists? ? (return true) : (return false)
  end

  def destroy
    scheduler_id = @resource.value(:scheduler_id)

    mysql([defaults_file, '-e', "DELETE FROM `scheduler` WHERE `id` = #{scheduler_id}"].compact)

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
    update_scheduler(@property_flush) if @property_flush
    @property_hash.clear

    load_to_runtime = @resource[:load_to_runtime]
    mysql([defaults_file, '-NBe', 'LOAD SCHEDULER TO RUNTIME'].compact) if load_to_runtime == :true

    save_to_disk = @resource[:save_to_disk]
    mysql([defaults_file, '-NBe', 'SAVE SCHEDULER TO DISK'].compact) if save_to_disk == :true
  end

  def update_scheduler(properties)
    scheduler_id = @resource.value(:scheduler_id)

    return false if properties.empty?

    values = []
    properties.each do |field, value|
      sql_value = make_sql_value(value)
      values.push("`#{field}` = #{sql_value}")
    end

    query = 'UPDATE `scheduler` SET '
    query << values.join(', ')
    query << " WHERE `id` = '#{scheduler_id}'"

    mysql([defaults_file, '-e', query].compact)
  end

  # Generates method for all properties of the property_hash
  mk_resource_methods

  def active=(value)
    @property_flush[:active] = value
  end

  def interval_ms=(value)
    @property_flush[:interval_ms] = value
  end

  def filename=(value)
    @property_flush[:filename] = value
  end

  def arg1=(value)
    @property_flush[:arg1] = value
  end

  def arg2=(value)
    @property_flush[:arg2] = value
  end

  def arg3=(value)
    @property_flush[:arg3] = value
  end

  def arg4=(value)
    @property_flush[:arg4] = value
  end

  def arg5=(value)
    @property_flush[:arg5] = value
  end

  def comment=(value)
    @property_flush[:comment] = value
  end
end
