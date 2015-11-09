define bareos::client::service_addr(
  $address='',
)
{
  $_address = $address ? { '' => $title, default => $address }

  @@bareos::client_definition { "${title}${bareos::client::name_suffix}":
    password       => $bareos::client::password,
    address        => $_address,
    job_retention  => $bareos::client::job_retention,
    file_retention => $bareos::client::file_retention,
    concurrency    => $bareos::client::concurrency,
    tag            => "bareos::server::${bareos::director}",
  }
}
