use Mojo::Util qw/dumper decamelize camelize/;
use Remote;
use strict;
use Getopt::Long::Descriptive;
 
my ($opt, $usage) = describe_options
    (
     'my-program %o <some-arg>',
     [ 'list|l',   "the port to connect to" ],
     [],
     [ 'verbose|v',  "print extra stuff"            ],
     [ 'help|',       "print usage message and exit", { shortcircuit => 1 } ],
    );
 
print($usage->text), exit if $opt->help;
 
$\ = "\n"; $, = "\t";

my $ua = Remote->new;

if ($opt->list) {
    print join ' ', $ua->commands;
    exit;
}

my $tx = $ua->get_playing_content_info;

print $tx->req->to_string;

print $tx->res->body;
