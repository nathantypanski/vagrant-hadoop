
class java {
  $java_home = "/usr/lib/jvm/java-7-oracle/"

  # This PPA hosts Oracle's Java package
  apt::ppa {'ppa:webupd8team/java':
  }

  # Oracle requires we accept the license before installing
  exec { 'accept-java-license':
    command => '/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections;/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 seen true | sudo /usr/bin/debconf-set-selections;',
    before => Package['oracle-java7-installer'],
  }
  package { 'oracle-java7-installer':
    require => [
                Apt::Ppa['ppa:webupd8team/java'],
               ],
    ensure => present,
  }

  file {'/etc/profile.d/set_java_home.sh':
    ensure => present,
    require => Package['oracle-java7-installer'],
    content => "export JAVA_HOME=${java_home}",
    mode => [
             'a+x',
            ],
  }

  Apt::Ppa['ppa:webupd8team/java'] -> Package['oracle-java7-installer']
}
