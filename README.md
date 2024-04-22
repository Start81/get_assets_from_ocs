# get_assets_from_ocs
Export inventory from ocs to a csv file

### prerequisites
This script uses theses libs : 
```
sudo cpan REST::Client Data::Dumper Monitoring::Plugin MIME::Base64 JSON LWP::UserAgent Readonly Text::CSV File::Basename IO::Socket::SSL
```

## Use case 
```bash
get_assets_from_ocs.pl 1.0.0

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
It may be used, redistributed and/or modified under the terms of the GNU
General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).

Create a csv export from ocs inventory

Usage: get_assets_from_ocs.pl -H <hostname>  -u <User> -P <password> -o <outputfile> [-t <timeout>] [-S]

 -?, --usage
   Print usage information
 -h, --help
   Print detailed help screen
 -V, --version
   Print version information
 --extra-opts=[section][@file]
   Read options from an ini file. See https://www.monitoring-plugins.org/doc/extra-opts.html
   for usage and examples.
 -H, --host=STRING
   Hostname
 -u, --user=string
   User name for api authentication
 -P, --Password=string
   User password for api authentication
 -S, --ssl
  ocs inventory use ssl
 -o, --utputfile
  Output File Full path
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: 120)
 -v, --verbose
   Show details for command-line debugging (can repeat up to 3 times)
```
sample to get an export :
```bash
perl get_assets_from_ocs.pl -H ocsinventory-ng -u USER -P P@ssWord -o c:/Mypath/My_export.csv -S
```




