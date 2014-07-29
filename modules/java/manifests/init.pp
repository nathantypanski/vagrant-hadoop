class java {

    # This PPA hosts Oracle's Java package
    apt::ppa {'ppa:webupd8team/java':}

    # Oracle requires we accept the license before installing
    exec { 'accept-java-license':
         command => '/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections;/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 seen true | sudo /usr/bin/debconf-set-selections;',
    } ->

    package { 'oracle-java7-installer':
            require => Exec['accept-java-license'],
            ensure => present,
    }

    Apt::Ppa['ppa:webupd8team/java'] -> Package['oracle-java7-installer']
}

include java
