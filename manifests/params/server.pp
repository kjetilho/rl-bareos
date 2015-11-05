class bareos::params::server {
  case $::operatingsystem {
    'Ubuntu': {
      $packages = ['bareos-database-postgresql',
                   'bareos-storage-tape',
                   'bareos-storage']
    }
  }
}
