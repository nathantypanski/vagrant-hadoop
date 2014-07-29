class { 'apt':
      always_apt_update    => true,
      disable_keys         => undef,
      proxy_host           => undef,
      proxy_port           => '8080',
      purge_sources_list   => false,
      purge_sources_list_d => false,
      purge_preferences_d  => undef,
      update_timeout       => undef,
}

file {'/home/vagrant/test1':
      ensure  => file,
      content => "Hi.\n",
}

file {'/home/vagrant/test2':
      ensure  => file,
      content => "Hello world\n",
}

apt::ppa {'ppa:webupd8team/java':}

exec { 'accept-java-license':
     command => '/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections;/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 seen true | sudo /usr/bin/debconf-set-selections;',
} ->

package { 'oracle-java7-installer':
        require => Exec['accept-java-license'],
        ensure => present,
}

Apt::Ppa['ppa:webupd8team/java'] -> Package['oracle-java7-installer']