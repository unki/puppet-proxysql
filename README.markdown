#### Table of Contents

1. [Overview](#overview)
2. [Setup - The basics of getting started with proxysql](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with proxysql](#beginning-with-proxysql)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

[![Build Status](https://travis-ci.org/voxpupuli/puppet-proxysql.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-proxysql)
[![Code Coverage](https://coveralls.io/repos/github/voxpupuli/puppet-proxysql/badge.svg?branch=master)](https://coveralls.io/github/voxpupuli/puppet-proxysql)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/proxysql.svg)](https://forge.puppet.com/puppet/proxysql)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/proxysql.svg)](https://forge.puppet.com/puppet/proxysql)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/proxysql.svg)](https://forge.puppet.com/puppet/proxysql)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/proxysql.svg)](https://forge.puppet.com/puppet/proxysql)

The proxysql module installs, configures and manages the [ProxySQL](https://github.com/sysown/proxysql) service.

This module will install the ProxySQL and manage it's configuration. It also extends Puppet to be able to manage `mysql_users`, `mysql_servers`, `mysql_replication_hostgroups`, `mysql_query_rules`, `proxysql_servers`, `scheduler` and `global_variables`.


## Setup

### Setup Requirements **OPTIONAL**

The module requires Puppet 4.10.0 over above.

It depends on the [puppetlabs](https://puppet.com/)/[mysql](https://github.com/puppetlabs/puppetlabs-mysql) module (>= 2.5.x) and on the [puppetlabs](https://puppet.com/)/[apt](https://github.com/puppetlabs/puppetlabs-apt) module (>= 2.1.x) when using deb based systems.

### Beginning with proxysql

To install the ProxySQL software with all the default options:
```puppet
include proxysql
```

You can customize options such as (but not limited to) `listen_port`, `admin_password`, `monitor_password`, ...
```puppet
  class { 'proxysql':
    listen_port              => 3306,
    admin_password           => Sensitive('654321'),
    monitor_password         => Sensitive('123456'),
    override_config_settings => $override_settings,
  }
```

You can configure users\hostgroups\rules\schedulers using class parameters
```puppet
  class { 'proxysql':
     mysql_servers    => [ 
       { 
         'db1' => { 
           'port' => 3306, 
           'hostgroup_id' => 1, 
         } 
       },
       { 
         'db2' => { 
           'hostgroup_id' => 2, 
         } 
       },
     ],
     mysql_users      => [ 
       { 
         'app' => { 
           'password' => '*92C74DFBDA5D60ABD41EFD7EB0DAE389F4646ABB', 
           'default_hostgroup' => 1, 
         } 
       },
       { 
         'ro'  => { 
           'password' => mysql_password('MyReadOnlyUserPassword'), 
           'default_hostgroup' => 2, 
         } 
       },
     ],
     mysql_hostgroups => [ 
       { 
         '1-2' => { 
           'writer_hostgroup' => 1, 
           'reader_hostgroup' => 2, 
         } 
       },
     ],
     mysql_group_replication_hostgroups => [
       {
         'hostgroup 2' => {
           'reader_hostgroup'        => 10,
           'writer_hostgroup'        => 5,
           'backup_writer_hostgroup' => 2,
           'offline_hostgroup'       => 11,
         }
       },
     ],
     mysql_rules      => [ 
       { 
         'mysql_query_rule-1' => { 
           'rule_id'         => 1,
           'match_pattern'   => 'testtable',
           'replace_pattern' => 'test.newtable',
           'apply'           => 1,
           'active'          => 1, 
         }
       },
     ],
     schedulers       => [ 
       { 
         'scheduler-1' => { 
           'scheduler_id'  => 1,
           'active'        => 0,
           'filename'      => '/usr/bin/whoami', 
         }
       },
     ],
```

Or by using individual resources:
```puppet
  class { 'proxysql':
    listen_port    => 3306,
    admin_password => Sensitive('SuperSecretPassword'),
  }

  proxy_mysql_server { '192.168.33.31:3306-31':
    hostname     => '192.168.33.31',
    port         => 3306,
    hostgroup_id => 31,
  }
  proxy_mysql_server { '192.168.33.32:3306-31':
    hostname     => '192.168.33.32',
    port         => 3306,
    hostgroup_id => 31,
  }
  proxy_mysql_server { '192.168.33.33:3306-31':
    hostname     => '192.168.33.33',
    port         => 3306,
    hostgroup_id => 31,
  }
  proxy_mysql_server { '192.168.33.34:3306-31':
    hostname     => '192.168.33.34',
    port         => 3306,
    hostgroup_id => 31,
  }
  proxy_mysql_server { '192.168.33.35:3306-31':
    hostname     => '192.168.33.35',
    port         => 3306,
    hostgroup_id => 31,
  }

  proxy_mysql_replication_hostgroup { '30-31':
    writer_hostgroup => 30,
    reader_hostgroup => 31,
    comment          => 'Replication Group 1',
  }
  proxy_mysql_replication_hostgroup { '20-21':
    writer_hostgroup => 20,
    reader_hostgroup => 21,
    comment          => 'Replication Group 2',
  }

  proxy_mysql_group_replication_hostgroup { '5-2-10-11':
    reader_hostgroup        => 10,
    writer_hostgroup        => 5,
    backup_writer_hostgroup => 2,
    offline_hostgroup       => 11,
  }

  proxy_mysql_user { 'tester':
    password          => 'testerpwd',
    default_hostgroup => 30,
  }

  proxy_mysql_query_rule { 'mysql_query_rule-1':
    rule_id               => 1,
    match_pattern         => '^SELECT',
    apply                 => 1,
    active                => 1,
    destination_hostgroup => 31,
  }

  proxy_scheduler { 'scheduler-1':
    scheduler_id => 1,
    active       => 0,
    filename     => '/usr/bin/whoami',
  }

  proxy_scheduler { 'scheduler-2':
    scheduler_id => 2,
    active       => 0,
    interval_ms  => 1000,
    filename     => '/usr/bin/id',
  }
```

## Usage

Configuration is done by the `proxysql` class.

### Customize config settings

You can override any configuration setting by using the `override_config_settings` hash. This hash resembles the structure of the `proxysql.cnf` file

```puppet
{
    admin_variables => {
      refresh_interval => 2000,
      ...
    },
    mysql_variables => {
      monitor_writer_is_also_reader => false,
      ...
    },
    mysql_servers => {
      '127.0.0.1:33061-1' => {
         'address'      => '127.0.0.1',
         'port'         => 33061,
         'hostgroup_id' => 1,
       },
      '127.0.0.1:33062-1' => {
         'address'      => '127.0.0.1',
         'port'         => 33062,
         'hostgroup_id' => 1,
       },
      ...
    },
    mysql_users => { ... },
    mysql_query_rules => { ... },
    scheduler => { ... },
    mysql_replication_hostgroups => { ... },

}
```

## Reference

### Public classes
* [`proxysql`](#proxysql): Installs and configures ProxySQL

### Private classes
* `proxysql::admin_credentials`: Manages the admin credentials and admin interfaces
* `proxysql::config`: Manages the configuration files and `global_variables`
* `proxysql::configure`: Manages the resources specified in the public class
* `proxysql::install`: Installs the package(s)
* `proxysql::param`: Manages the default parameters
* `proxysql::prerequisites`: Manages the user / group to own the proxysql files
* `proxysql::reload_config`: Reloads admin and mysql variables if you enable the `manage_config_file` option
* `proxysql::repo`: Manages the repo's where ProxySQL might be in.
* `proxysql::service`: Manages the service

### parameters
#### `proxysql`
##### `package_name`
The name of the ProxySQL package in your package manager. Defaults to 'proxysql'

##### `package_ensure`
The ensure of the ProxySQL package resource. Defaults to 'latest'

##### `service_name`
The name of the ProxySQL service resource. Defaults to 'proxysql'

##### `service_ensure`
The ensure of the ProxySQL service resource. Defaults to 'running'

##### `datadir`
The directory where ProxySQL will store it's data. defaults to '/var/lib/proxysql'

##### `listen_ip`
The ip where the ProxySQL service will listen on. Defaults to '0.0.0.0' aka all configured IP's on the machine

##### `listen_port`
The port where the ProxySQL service will listen on. Defaults to '6033'

##### `listen_socket`
The socket where the ProxySQL service will listen on. Defaults to '/tmp/proxysql.sock'

##### `admin_username`
The username to connect to the ProxySQL admin interface. Defaults to 'admin'

##### `admin_password`
The password to connect to the ProxySQL admin interface. Defaults to 'admin'

##### `admin_listen_ip`
The ip where the ProxySQL admin interface will listen on. Defaults to '127.0.0.1'

##### `admin_listen_port`
The port where the ProxySQL admin interface  will listen on. Defaults to '6032'

##### `admin_listen_socket`
The socket where the ProxySQL admin interface  will listen on. Defaults to '/tmp/proxysql_admin.sock'

##### `monitor_username`
The username ProxySQL will use to connect to the configured mysql_servers. Defaults to 'monitor'

##### `monitor_password`
The password ProxySQL will use to connect to the configured mysql_servers. Defaults to 'monitor'

##### `config_file`
The file where the ProxySQL configuration is saved. This will only be configured if `manage_config_file` is set to `true`.
Defaults to '/etc/proxysql.cnf'

##### `manage_config_file`
Determines wheter this module will configure the ProxySQL configuration file. Defaults to 'true'

##### `mycnf_file_name`
Path of the my.cnf file where the connections details for the admin interface is save. This is required for the providers to work.
This will only be configured if `manage_mycnf_file` is set to `true`. Defaults to '/root/.my.cnf'

##### `manage_mycnf_file`
Determines wheter this module will configure the my.cnf file to connect to the admin interface. Defaults to 'true'

##### `restart`
Determines wheter this module will restart ProxySQL after reconfiguring the config file. Defaults to 'false'

##### `load_to_runtime`
Specifies wheter te managed ProxySQL resources should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter te managed ProxySQL resources should be immediately save to disk. Boolean, defaults to 'true'.

##### `manage_repo`
Determines wheter this module will manage the repositories where ProxySQL might be. Defaults to 'true'

##### `repo`
These are the repo's we will configure. Currently only Debian is supported. This hash will be passed on to `apt::source` or `yumrepo` (depending on the OS family).
Defaults to the official upstream repo for your OS. See http://repo.proxysql.com for more info.


##### `package_source`
location ot the proxysql package for the `package_provider`.
 - Default to 'https://github.com/sysown/proxysql/releases/download/v1.4.7/proxysql-1.4.7-1-centos7.x86_64.rpm' for RedHat based systems
 - Default to 'https://github.com/sysown/proxysql/releases/download/v1.4.7/proxysql_1.4.7-ubuntu16_amd64.deb' for Debian based systems

##### `package_provider`
provider for package-resource. defaults to `dpkg` for debian-based, `rpm` for redhat base or `undef` for others

##### `sys_owner`
owner of the datadir and config_file, defaults to 'root'

##### `sys_group`
group of the datadir and config_file, defaults to 'root'

##### `override_config_settings`
Which configuration variables should be overriden. Hash, defaults to `{}` (empty hash).

##### `cluster_name`
If set, proxysql_servers with the same cluster_name will be automatically added to the same cluster and will synchronize their configuration parameters.
Defaults to undef

##### `cluster_username`
The username ProxySQL will use to connect to the configured mysql_clusters
Defaults to 'cluster'

##### `cluster_password`
The password ProxySQL will use to connect to the configured mysql_clusters. Defaults to 'cluster'

##### `mysql_client_package_name`
The name of the mysql client package in your package manager. Defaults to undef

##### `manage_hostgroup_for_servers`
Determines wheter this module will manage hostgroup_id for mysql_servers.
If false - it will skip difference in this value between manifest and defined in ProxySQL. Defaults to 'true'

##### `mysql_servers`
Array of mysql_servers, that will be created in ProxySQL. Defaults to undef

##### `mysql_users`
Array of mysql_users, that will be created in ProxySQL. Defaults to undef

#####` mysql_hostgroups`
Array of mysql_hostgroups, that will be created in ProxySQL. Defaults to undef

##### `mysql_rules`
Array of mysql_rules, that will be created in ProxySQL. Defaults to undef

##### `schedulers`
Array of schedulers, that will be created in ProxySQL. Defaults to undef
##### `split_config`
If set, ProxySQL config file will be split in 2: main config file with admin and mysql variables and proxy config file with servers\users\hostgroups\scheduler\rules params. Defaults to false

##### `proxy_config_file`
The file where servers\users\hostgroups\scheduler\rules params of ProxySQL configuration are saved. This will only be configured if `split_config` is set to `true`. Defaults to 'proxysql_proxy.cnf'

#####`manage_proxy_config_file`
Determines wheter this module will update the ProxySQL proxy configuration file. Defaults to 'true'

## Types
#### proxy_global_variable
`proxy_global_variable` manages a variable in the ProxySQL `global_variables` admin table.

##### `name`
The name of the variable.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `value`
The value of the variable.

#### proxy_cluster
`proxy_cluster` manages an entry in the ProxySQL `proxysql_clusters` admin table.

##### `name`
The name of the resource.

##### `hostname`
Hostname of the server. Required.

##### `port`
Port of the server. Required. Defaults to 3306.

#### proxy_mysql_replication_hostgroup
`proxy_mysql_replication_hostgroup` manages an entry in the ProxySQL `mysql_replication_hostgroups` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
Name to describe the hostgroup config. Must be in a '`writer_hostgroup`-`reader_hostgroup`' format.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `writer_hostgroup`
Id of the writer hostgroup. Required.

##### `reader_hostgroup`
Id of the reader hostgroup. Required.

##### `comment`
Optional comment.

#### mysql_group_replication_hostgroup
`mysql_group_replication_hostgroup` manages an entry in the ProxySQL `mysql_group_replication_hostgroups` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
Name to describe the hostgroup config. Must be in a '`writer_hostgroup`-`backup_writer_hostgroup`-`reader_hostgroup`-`offline_hostgroup`' format.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `writer_hostgroup`
Id of the writer hostgroup. Required.

##### `backup_writer_hostgroup`
Id of the backup writer hostgroup. Required.

##### `reader_hostgroup`
Id of the reader hostgroup. Required.

##### `offline_hostgroup`
Id of the offline hostgroup. Required.

##### `active`
Specifies wheter the resource is active or not. Integer, defaults to 1.

##### `max_writers`
Specifies how many active writers the resource has. Integer, defaults to 1.

##### `writer_is_also_reader`
Specifies if the writer is also a reader. Integer, defaults to 0.

##### `max_transactions_behind`
Specifies how many transactions a resource can be behind the "master" until shunned. Integer, defaults to 0.

##### `comment`
Optional comment.

#### proxy_mysql_server
`proxy_mysql_server` manages an entry in the ProxySQL `mysql_servers` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
Name to describe the hostgroup config. Must be in a '`hostname`:`port`-`hostgroup_id`' format.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `hostgroup_id`
Id of the hostgroup this server wil be configured to be part of. Integer value, required.

##### `hostname`
Hostname of the server. Required.

##### `port`
Port of the server. Required. Defaults to 3306.

##### `status`
Status of the server. Should be one of the following values: 'ONLINE', 'OFFLINE_SOFT', 'OFFLINE_HARD', 'SHUNNED'. Defaults to 'ONLINE'.

##### `weight`
Weight value of the server. The higher the value, the higher the probability this server will be chosen from the hostgroup. Integer, defaults to 1.

##### `compression`
Compression value of the serer. If the value is greater than 0, new connections to that server will use compression. Integer, defaults to 0.

##### `max_connections`
The maximum number of connections ProxySQL will open to this backend server. Even though this server will have the highest weight, no new connections will be opened to it once this limit is hit. Please ensure that the backend is configured with a correct value of max_connections to avoid that ProxySQL will try to go beyond that limit. Integer, defaults to 1000.

##### `max_replication_lag`
If greater and 0, ProxySQL will reguarly monitor replication lag and if it goes beyond such threshold it will temporary shun the host until replication catch ups. Integer, defaults to 0.

##### `use_ssl`
If set to 1, connections to the backend will use SSL. Values 0 or 1. Defaults to 0.

##### `max_latency_ms`
Ping time is regularly monitored. If a host has a ping time greater than max_latency_ms it is excluded from the connection pool (although the server stays ONLINE. Integer, defaults to 0.

##### `comment`
Optional comment.


#### proxy_mysql_user
`proxy_mysql_user` manages an entry in the ProxySQL `mysql_users` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
Username for the user. Required.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `encrypt_password`
Specifies wheter the user password should be encrypted (requires ProxySQL setting `admin-hash_password` = `true`). Boolean, defaults to 'true'.

##### `password`
Password for the user. Required.
*Note*: you should make sure that the global variable `admin-hashed_passwords` is set to `true` and then encrypt this password using the `mysql_password()` function.

##### `active`
Flag to determine if this user is active or not. Values 0 or 1. Defaults to 1.

##### `use_ssl`
Flag to determine if this user uses SSL or not. Values 0 or 1. Defaults to 0.

##### `default_hostgroup`
Default hostgroup for the user. Integer, defaults to 0.

##### `default_schema`
Default schema for the user. String, defaults to ''.

##### `schema_locked`
Is the user locked in the `default_schema` or not. Values 0 or 1. Defaults to 0.

##### `transaction_persistent`
Disable routing across hostgroups once a transaction has started for a specific user. Values 0 or 1. Defaults to 0.

##### `fast_forward`
Flag to determine fast forward or not. Values 0 or 1. Defaults to 0.

##### `backend`
Is this a backend user. Values 0 or 1. Defaults to 1.

##### `frontend`
Is this a frontend user. Values 0 or 1. Defaults to 1.


#### proxy_mysql_query_rule
`proxy_mysql_query_rule` manages an entry in the ProxySQL `mysql_query_rules` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
The name of the query rule entry, Must be in a 'mysql_query_rule-`rule_id`' format.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `rule_id`
Id of the scheduler entry. Integer value, required.

##### `active`
Is the rule active or not. Boolean value 0 or 1, defaults to 0.

##### `username`
Username to apply this rule to. String, defaults to NULL.

##### `schemaname`
Schema to apply this rule to. String, defaults to NULL.

##### `flag_in`
Used to chain rules. This is the id of the previous rule to apply. Integer, defaults to 0.

##### `flag_out`
Used to chain rules. This is the id of the next rule to apply, Integer, defaults to NULL

##### `apply`
Used to chain rules.

##### `client_addr`
Match traffic from a certain address. String, defaults to NULL.

##### `proxy_addr`
Match incoming traffic on a specific local address. String, defaults to NULL.

##### `proxy_port`
Match incoming traffic on a specific local port. Integer, defaults to NULL.

##### `digest`
match queries with a specific digest, as returned by `stats_mysql_query_digest`.`digest`. String, defaults to NULL.

##### `match_digest`
regular expression that matches the query digest. String, defaults to NULL.

##### `match_pattern`
regular expression that matches the query text. String, defaults to NULL.

##### `replace_pattern`
this is the pattern with which to replace the matched pattern. String, defaults to NULL.

##### `negate_match_pattern`
if this is set to 1, only queries not matching the query text will be considered as a match. This acts as a NOT operator in front of the regular expression matching against match_pattern or match_digest. Boolean value 0 or 1, defaults to 0.

##### `destination_hostgroup`
The hostgroup to send this query to. Integer, defaults to NULL.

##### `cache_ttl`
The amount of miliseconds to cache the result of this query. Integer, defaults to NULL.

##### `reconnect`
feature currently not in use.

##### `timeout`
The maximum amount of miliseconds in which the matched or rewritten query should be executed. Integer, defaults to NULL.

##### `retries`
The maximum number of times a query needs to be re-executed in case of detected failure during the execution of the query. Integer, defaults to NULL.

##### `delay`
The number of milliseconds to delay the execution of the query. Integer, defaults to NULL.

##### `error_msg`
The query will be blocked, and the specified error_msg will be returned to the client. String, defaults to NULL.

##### `log`
The query will be logged. Boolean value 0 or 1, defaults to NULL.

##### `mirror_hostgroup`
see https://github.com/sysown/proxysql/blob/master/doc/mirroring.md. Integer, defaults to NULL.

##### `mirror_flag_out`
see https://github.com/sysown/proxysql/blob/master/doc/mirroring.md. Integer, defaults to NULL.

##### `comment`
Optional free form text field, usable for a descriptive comment of the query rule.


#### proxy_scheduler
`proxy_scheduler` manages an entry in the ProxySQL `scheduler` admin table.

##### `ensure`
Whether the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.

##### `name`
The name of the scheduler entry, Must be in a 'scheduler-`scheduler_id`' format.

##### `load_to_runtime`
Specifies wheter the resource should be immediately loaded to the active runtime. Boolean, defaults to 'true'.

##### `save_to_disk`
Specifies wheter the resource should be immediately save to disk. Boolean, defaults to 'true'.

##### `scheduler_id`
Id of the scheduler entry. Integer value, required.

##### `filename`
The filename of the scheduler script to run. Required.

##### `interval_ms`
Interval in which to run this scheduler. In miliseconds, Integer, defaults to 10000 (10sec).

##### `arg1`
The 1st argument for the scheduler script to run. Optional, defaults to NULL.

##### `arg2`
The 2nd argument for the scheduler script to run. Optional, defaults to NULL.

##### `arg3`
The 3rd argument for the scheduler script to run. Optional, defaults to NULL.

##### `arg4`
The 4th argument for the scheduler script to run. Optional, defaults to NULL.

##### `arg5`
The 5th argument for the scheduler script to run. Optional, defaults to NULL.

##### `comment`
Optional comment.

## Limitations

The module requires Puppet 4.10.0 or above.

## Development

This module is originally developed by [Matthias Crauwels](mailto:matthias@crauwels.net) for use at [Ghent University, Belgium](http://www.ugent.be). This module is published under the Apache 2.0 license.

We are open to feature requests, bug reports, contributions, etc...

## Contributors

Original author: Matthias Crauwels
