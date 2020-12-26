package Remote;

use Mojo::Base 'Mojo::UserAgent';
use Mojo::Util qw/dumper decamelize camelize/;

use Class::Method::Modifiers;

has 'address' => '192.168.1.128';
has 'client_id';
has 'device_name';

has 'auth';

my $device_name = 'my device name';
my $client_id = "$device_name:1";

my $data =
    {
     getApplicationList => {
			    "url" => "appControl",
			    "method" =>  "getApplicationList",
			    "id" =>  60,
			    "params" =>  [],
			    "version" =>  "1.0"
			   },
     getApplicationStatusList => {
				  "url" => "appControl",
				  "method" =>  "getApplicationStatusList",
				  "id" =>  55,
				  "params" =>  [],
				  "version" =>  "1.0"
				 },
     getPowerStatus => {
			url => 'system',
			'method' => 'getPowerStatus',
			'params' =>[],
			'id' => 10,
			'version' =>'1.0'
		       },
     actRegister => {
		     'url' => 'accessControl',
		     'id' => 13,
		     'method' => 'actRegister',
		     'version' => '1.0',
		     'params' => [
				  {
				   'clientid' => $client_id,
				   'nickname' => $device_name
				  },
				  [{
				    'clientid' => $client_id,
				    'value' => 'yes',
				    'nickname' => $device_name,
				    'function' => 'WOL'
				   }]
				 ]
		    },
     getPlayingContentInfo => {
			       "url" => 'avContent',
			       "method" =>  "getPlayingContentInfo",
			       "id" =>  103,
			       "params" =>  [],
			       "version" =>  "1.0"
			      },
     getSourceList => {
		       "url" => "avContent",
		       "method" =>  "getSourceList",
		       "id" =>  1,
		       "params" =>  [{"scheme", "extInput"}],
		       "version" =>  "1.0"
		      },
     getApplicationStatusList => {
				  "url" => "appControl",
				  "method" =>  "getApplicationStatusList",
				  "id" =>  55,
				  "params" =>  [],
				  "version" =>  "1.0"
				 },
     getCurrentExternalInputsStatus => {
					"url" => "avContent",
					"method" =>  "getCurrentExternalInputsStatus",
					"id" =>  105,
					"params" =>  [],
					"version" =>  "1.0"
				       }
     
    };

my $auth;

around 'new' => sub {
    my $orig = shift;

    my $ua = $orig->(@_);

    my $tx = $ua->post('http://192.168.1.128/sony/' . $data->{actRegister}->{url}, json => $data->{actRegister});

    if ($tx->res->is_success) {
	$auth = [ map { $_->value } grep { $_->name eq 'auth' } @{$tx->res->cookies} ]->[0] || die;

	$ua->on(start => sub {
		    my ($ua, $tx) = @_;
		});
	return $ua;
    } else {

    }
};

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $program = $AUTOLOAD;
    $program =~ s/.*:://;


    # print $program;
    my $promise = $program =~ /_p$/;
    $program =~ s/_p$//;

    my $thing = lcfirst camelize $program;

    my $data = $data->{$thing};

    # print $program, $thing, $promise;
    # print dumper $data;

    return $promise ?
    	$self->max_redirects(3)->post_p('http://' . $self->address . '/sony/' . $data->{url} => json => $data)
	:
    	$self->max_redirects(3)->post('http://' . $self->address . '/sony/' . $data->{url} => json => $data)
    }

sub commands {
    return map { decamelize(ucfirst $_) } keys %$data;
}


1;
