#!/usr/bin/perl -w 
#===============================================================================
# Script Name   : get_assets_from_ocs.pl
# Usage Syntax  : get_assets_from_ocs.pl [-v] -t [<TIMEOUT>] -H <HOSTNAME> -u <USER> -P <MDP> -o <FILEPATH> [-S]
# Author        : Start81 (DESMAREST JULIEN)
# Version       : 1.0.0
# Last Modified : 22/04/2024 
# Modified By   : Start81 (DESMAREST JULIEN)
# Description   : Export ocs inventory
# Depends On    : REST::Client, Data::Dumper, JSON, Readonly, MIME::Base64, LWP::UserAgent, Text::CSV, File::Basename, Monitoring::Plugin 
#
# Changelog:
#    Legend:
#       [*] Informational, [!] Bugix, [+] Added, [-] Removed
#
# - 28/09/2021 | 1.0.0 | [*] initial realease
#===============================================================================
use utf8; 
use strict;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use warnings;
use MIME::Base64;
use LWP::UserAgent;
use Data::Dumper;
use REST::Client;
use JSON;
use Text::CSV qw( csv );
use Readonly;
use File::Basename;
use Monitoring::Plugin;
Readonly our $VERSION => '1.0.0';
my $o_verb;
sub verb { my $t=shift; if ($o_verb) {print $t,"\n"}  ; return 0}
my $np = Monitoring::Plugin->new(
    usage => "Usage: %s -H <hostname>  -u <User> -P <password> -o <outputfile> [-t <timeout>] [-S] \n",
    plugin => basename($0),
    shortname => 'Export Ocs object',
    blurb => 'Create a csv export from ocs inventory',
    version => $VERSION,
    timeout => 120
);
$np->add_arg(
    spec => 'host|H=s',
    help => "-H, --host=STRING\n"
          . '   Hostname',
    required => 1
);
$np->add_arg(
    spec => 'user|u=s',
    help => "-u, --user=string\n"
          . '   User name for api authentication',
    required => 1,
);
$np->add_arg(
    spec => 'Password|P=s',
    help => "-P, --Password=string\n"
          . '   User password for api authentication',
    required => 1,
);

$np->add_arg(
    spec => 'ssl|S',
    help => "-S, --ssl\n"  
         . '  ocs inventory use ssl',
    required => 0
);
$np->add_arg(
    spec => 'outputfile|o=s',
    help => "-o, --utputfile\n"  
         . '  Output File Full path',
    required => 1
);
my @header = ("ID","LASTDATE","NAME","USERID","OSNAME","WORKGROUP","OSVERSION","PROCESSORN","MMANUFACTURER","SSN",
             "SMODEL","MEMORY","IPADDR","DNS","DEFAULTGATEWAY","ARCH","ARCHIVE");
$np->getopts;            
my $o_hostname=$np->opts->host;
my $o_login = $np->opts->user;
my $o_pwd= $np->opts->Password;
my $client = REST::Client->new();
my $url = "http://";
my $o_use_ssl = 0;
$o_use_ssl = $np->opts->ssl if (defined $np->opts->ssl);
my $o_timeout_qry=30;
my $o_timeout=$np->opts->timeout;
my $o_csv_path=$np->opts->outputfile;
$o_verb = $np->opts->verbose;
alarm($o_timeout);
$client->addHeader('Content-Type', 'application/json');
$client->addHeader('Accept', 'application/json');
$client->addHeader('Accept-Encoding',"gzip, deflate, br");
if ($o_use_ssl) {
    my $ua = LWP::UserAgent->new(
        timeout  => $o_timeout_qry,
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE
        },
    );
    $url = "https://";
    $client->setUseragent($ua);
}
my $url_api = "$url$o_hostname/ocsapi/v1";
my $url_list_id = "$url_api/computers/listID";
my $url_hardware;
verb($url_list_id);
$client->addHeader('Authorization', 'Basic ' . encode_base64("$o_login:$o_pwd"));
$client->GET($url_list_id);
my $msg;
if($client->responseCode() ne '200'){
    $msg = "Error response code : " . $client->responseCode() . " Message : Error when getting id list ". $client->{_res}->decoded_content ."\n";
    $np->plugin_exit('UNKNOWN', $msg) ;
}           
my $Lst_id_rep = $client->{_res}->decoded_content;
my $Lst_id = from_json($Lst_id_rep);
my $i=0;
my $item_response;
my $item;
my $csv = Text::CSV->new ({ sep_char => ";",eol =>"\n"});
my $fh ;
open $fh, ">:encoding(utf8)", $o_csv_path or die "$o_csv_path: $!";
$csv->print ($fh, $_) for \@header;
my $hardware;
my $bios;
while (exists ($Lst_id->[$i]->{'ID'})){
    my $id = $Lst_id->[$i]->{'ID'};
    $url_hardware="$url_api/computer/$id/bios";
    verb($url_hardware);
    $client->GET($url_hardware);
    
    if($client->responseCode() ne '200'){
       $msg = "Error response code : " . $client->responseCode() . " Message : Error when getting asset details ". $client->{_res}->decoded_content ."\n";
       print $msg ;
       close $fh or die "failed to close $o_csv_path: $!";
       $np->plugin_exit('UNKNOWN', $msg) ;
    }
    $item_response=$client->{_res}->decoded_content;
    $item = from_json($item_response);
    my @datarow;
    $hardware = $item->{$id}->{'hardware'};
    if (exists $item->{$id}->{'bios'}){
        $bios = $item->{$id}->{'bios'}->[0];
        @datarow = ($id,$hardware->{'LASTDATE'},$hardware->{'NAME'},$hardware->{'USERID'},$hardware->{'OSNAME'},
            $hardware->{'WORKGROUP'}, $hardware->{'OSVERSION'},$hardware->{'PROCESSORN'},
            $bios->{'MMANUFACTURER'},$bios->{'SSN'},$bios->{'SMODEL'},$hardware->{'MEMORY'},
            $hardware->{'IPADDR'},$hardware->{'DNS'},$hardware->{'DEFAULTGATEWAY'},$hardware->{'ARCH'},$hardware->{'ARCHIVE'});
    
    }else {

        @datarow = ($id,$hardware->{'LASTDATE'},$hardware->{'NAME'},$hardware->{'USERID'},$hardware->{'OSNAME'},
            $hardware->{'WORKGROUP'}, $hardware->{'OSVERSION'},$hardware->{'PROCESSORN'},
            "","","",$hardware->{'MEMORY'},$hardware->{'IPADDR'},$hardware->{'DNS'},$hardware->{'DEFAULTGATEWAY'},$hardware->{'ARCH'},$hardware->{'ARCHIVE'});
    }
    $csv->print($fh, \@datarow);
    $i++;
   
}
close $fh or die "failed to close $o_csv_path: $!";
print "wrote assets list in $o_csv_path";



