class bareos::server::install(
  $packages = $bareos::params::server::packages,
) inherits bareos::params::server
{
  validate_array($packages)
  ensure_packages($packages)
}


  
