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

include java
include stdlib
include wget

$apache_mirror = 'http://www.us.apache.org/dist/hadoop/core'
$hadoop_user = 'hduser'
$hadoop_group = 'hadoop'
$hadoop_mirror = 'http://www.poolsaboveground.com/apache/hadoop/core'
$hadoop_version = '2.4.1'
$hadoop_sig = "${apache_mirror}/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz.asc"
$hadoop_tarball = "/root/hadoop-${hadoop_version}.tar.gz"
$hadoop_root = "/opt/hadoop-${hadoop_version}"


package{'rsync':
  ensure => present,
}

package{'gpgv':
  ensure => present,
}

group{"${hadoop_group}":
  ensure => present,
}

user{"${hadoop_user}":
  name => "${hadoop_user}",
  ensure => present,
  require => Group["${hadoop_group}"],
  gid => "${hadoop_group}",
  home => "/home/${hadoop_user}",
  managehome => true,
}

$hadoop_keypath='/tmp/hadoop_key'
wget::fetch{'hadoop public key':
  source => 'http://www.us.apache.org/dist/hadoop/common/KEYS',
  destination => $hadoop_keypath,
  cache_dir => '/var/cache/wget',
} ->
exec{"import hadoop public key":
  command => "/usr/bin/gpg --import ${hadoop_keypath}",
  require => Package['gpgv'],
}

wget::fetch{'download hadoop signature':
  require => User["${hadoop_user}"],
  source => $hadoop_sig,
  destination => "/root/hadoop-${hadoop_version}.tar.gz.asc",
} ->
wget::fetch{'download hadoop':
  source => "${hadoop_mirror}/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz",
  destination => $hadoop_tarball,
  cache_dir => '/var/cache/wget',
}

exec{"hadoop tarball signature check":
  command => "/usr/bin/gpg ${hadoop_tarball}.asc",
  require => [
              Package['gpgv'],
              Wget::Fetch['download hadoop']
             ],
  before => Exec['extract hadoop'],
}

exec{"extract hadoop":
  command => "tar xf ${hadoop_tarball} -C /opt",
  creates => $hadoop_root,
  path    => ["/usr/bin", "/bin"],
}

class disable_ipv6 {
    file_line{'disable ipv6 all':
      path => '/etc/sysctl.conf',
      line => 'net.ipv6.conf.all.disable_ipv6 = 1',
      match => '^net.ipv6.conf.all.disable_ipv6.*$',
    }
    file_line{'disable ipv6 loopback':
      path => '/etc/sysctl.conf',
      line => 'net.ipv6.conf.lo.disable_ipv6 = 1',
      match => '^net.ipv6.conf.lo.disable_ipv6.*$',
    }
    file_line{'disable ipv6 default':
      path => '/etc/sysctl.conf',
      line => 'net.ipv6.conf.default.disable_ipv6 = 1',
      match => '^net.ipv6.conf.default.disable_ipv6.*$',
    }
}
include disable_ipv6
