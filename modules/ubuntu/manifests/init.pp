class {'ubuntu':
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
}

include ubuntu
