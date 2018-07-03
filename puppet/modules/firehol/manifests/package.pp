# Install the FireHOL package
#
# @param ensure Ensure value for the Package resource.
class firehol::package (
  $ensure = 'present'
) {

  ensure_resource('package', 'firehol', {
    ensure  => $ensure,
  })

}
