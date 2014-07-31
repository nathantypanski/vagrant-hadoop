
# package manager configuration
class {'apt':
  always_apt_update    => true,
  disable_keys         => undef,
  proxy_host           => undef,
  proxy_port           => '8080',
  purge_sources_list   => false,
  purge_sources_list_d => false,
  purge_preferences_d  => undef,
  update_timeout       => undef,
}

# install Oracle's java
include java
# Nice Puppet features
include stdlib
# Needed to download the tarball
include wget

# User to run Hadoop under.
$hadoop_user = 'hduser'

# Group for accounts with acess to Hadoop.
$hadoop_group = 'hadoop'

# Hadoop users's home folder
$hadoop_user_home = "/home/${hadoop_user}"

# Mirror we're using for Hadoop
$hadoop_mirror = 'http://www.poolsaboveground.com/apache/hadoop/core'

# Version of hadoop to use.
$hadoop_version = '2.4.1'

# Apache's official mirrof of Hadoop (be nice, don't download from this!)
$apache_mirror = 'http://www.us.apache.org/dist/hadoop/core'

# Path to an official signature for Hadoop tarball.
$hadoop_sig = "${apache_mirror}/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz.asc"

# The path to the Hadoop tarball after it's downloaded.
$hadoop_tarball = "/root/hadoop-${hadoop_version}.tar.gz"

# The place to which Hadoop will be installed.
$hadoop_root = "/opt/hadoop-${hadoop_version}"

# path to vagrant share
$vagrant_data = "/vagrant_data"


package{'rsync':
  ensure => present,
}

package{'gpgv':
  ensure => present,
}

class install_hadoop {
    group{"${hadoop_group}":
      ensure => present,
    }

    user{"${hadoop_user}":
      name => "${hadoop_user}",
      ensure => present,
      require => Group["${hadoop_group}"],
      gid => "${hadoop_group}",
      shell => '/bin/bash',
      home => $hadoop_user_home,
      managehome => true,
    } ->
    file{"${hadoop_user_home}/.bashrc":
      ensure => present,
      content => template('site/profile.erb'),
    }

    $hadoop_keypath='/tmp/hadoop_key'

    wget::fetch{'hadoop public key':
      source      => 'http://www.us.apache.org/dist/hadoop/common/KEYS',
      destination => $hadoop_keypath,
      cache_dir   => '/var/cache/wget',
    } ->
    exec{"import hadoop public key":
      command => "/usr/bin/gpg --import ${hadoop_keypath}",
      require => Package['gpgv'],
      unless  => "/usr/bin/test -d ${hadoop_root}",
    }

    wget::fetch{'download hadoop signature':
      require     => User["${hadoop_user}"],
      source      => $hadoop_sig,
      destination => "/root/hadoop-${hadoop_version}.tar.gz.asc",
    } ->
    wget::fetch{'download hadoop':
      source      => "${hadoop_mirror}/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz",
      destination => $hadoop_tarball,
      cache_dir   => '/var/cache/wget',
    }

    exec{"hadoop tarball signature check":
      command => "/usr/bin/gpg ${hadoop_tarball}.asc",
      require => [
                  Package['gpgv'],
                  Wget::Fetch['download hadoop']
                 ],
      before => Exec['extract hadoop'],
      unless => "/usr/bin/test -d ${hadoop_root}",
    }

    exec{"extract hadoop":
      command => "tar xf ${hadoop_tarball} -C /opt",
      creates => $hadoop_root,
      path    => ["/usr/bin", "/bin"],
    }
}

# Apparently Hadoop networking on Ubuntu doesn't always play nice with ipv6.
# Disable it; we don't need it anyway.
class disable_ipv6 {
    file_line{'disable ipv6 all':
      path  => '/etc/sysctl.conf',
      line  => 'net.ipv6.conf.all.disable_ipv6 = 1',
      match => '^net.ipv6.conf.all.disable_ipv6.*$',
    }
    file_line{'disable ipv6 loopback':
      path  => '/etc/sysctl.conf',
      line  => 'net.ipv6.conf.lo.disable_ipv6 = 1',
      match => '^net.ipv6.conf.lo.disable_ipv6.*$',
    }
    file_line{'disable ipv6 default':
      path  => '/etc/sysctl.conf',
      line  => 'net.ipv6.conf.default.disable_ipv6 = 1',
      match => '^net.ipv6.conf.default.disable_ipv6.*$',
    }
}
include disable_ipv6

$fs_default_name = 'hdfs://localhost:9000'
# in a single node setup we have replication of 1
$hdfs_site_dfs_replication = '1'
$mapred_job_tracker = 'localhost:9001'

class hadoop_site_config {
  require disable_ipv6, install_hadoop

  # hyphenated instead of underscore because that's the filename
  file{'core-site.xml':
    ensure  => present,
    path    => "${hadoop_root}/etc/hadoop/core-site.xml",
    content => template('site/core-site.xml.erb'),
  }
  file{'hdfs-site.xml':
    ensure  => present,
    path    => "${hadoop_root}/etc/hadoop/hdfs-site.xml",
    content => template('site/hdfs-site.xml.erb'),
  }
  file{'mapred-site.xml':
    ensure  => present,
    path    => "${hadoop_root}/etc/hadoop/mapred-site.xml",
    content => template('site/mapred-site.xml.erb'),
  }
  ## Not working yet:
  # file{'hadoop_key':
  #   ensure => present,
  #   path   => "${hadoop_user_home}/.ssh/id_dsa",
  #   source => "${vagrant_data}/insecure_hadoop_key",
  #   owner  => $hadoop_user,
  #   mode   => 0600,
  # }
  # file{'hadoop_public_key':
  #   ensure => present,
  #   path   => "${hadoop_user_home}/.ssh/id_dsa.pub",
  #   source => "${vagrant_data}/insecure_hadoop_key.pub",
  #   owner  => $hadoop_user,
  #   mode   => 0644,
  # }
  # file{'hadoop_authorized_keys':
  #   ensure  => present,
  #   require => [File['hadoop_public_key'], File['hadoop_key']],
  #   path    => "${hadoop_user_home}/.ssh/authorized_keys",
  #   source  => "${hadoop_user_home}/id_dsa.pub",
  #   mode    => 0600,
  # }
}

include hadoop_site_config
