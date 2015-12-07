define bareos::client::service_addr(
  $address='',
  $job_retention = $bareos::client::job_retention,
  $file_retention = $bareos::client::file_retention,
  $concurrency = $bareos::client::concurrency,
)
{
  $_address = $address ? { '' => $title, default => $address }

  @@bareos::client_definition { "${::fqdn}/${title}${bareos::client::name_suffix}":
    password       => $bareos::client::password,
    address        => $_address,
    job_retention  => $job_retention,
    file_retention => $file_retention,
    concurrency    => $concurrency,
    security_zone  => $bareos::security_zone,
    tag            => "bareos::server::${bareos::director}",
  }
}
