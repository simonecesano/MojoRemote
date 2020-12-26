use Mojo::UserAgent;
use Mojo::Loader qw(data_section find_modules load_class);
use Mojo::JSON qw/decode_json/;
use Mojo::Util qw/dumper/;
use strict;
use Getopt::Long::Descriptive;
 
my ($opt, $usage) = describe_options
    (
     'my-program %o <some-arg>',
     [ 'list|l:s', "list commands" ],
     [ 'power|p',  "get power status" ],
     [],
     [ 'verbose|v',  "print extra stuff"            ],
     [ 'help|h',       "print usage message and exit", { shortcircuit => 1 } ],
);
 
print($usage->text), exit if $opt->help;

my $ua = Mojo::UserAgent->new;

my $config = {
	   device_name => 'my device name'
	  };

my $client_id = "my device name:1";

my $json = '{"id": 13, "method": "actRegister", "version": "1.0", "params": [{"clientid": "my device name:1", "nickname": "my device name"}, [{"clientid": "my device name:1", "value": "yes", "nickname": "my device name", "function": "WOL"}]]}';

my $data = decode_json($json);

# print dumper $data;

my $data = {
	    'id' => 13,
	    'method' => 'actRegister',
	    'version' => '1.0',
	    'params' => [
			 {
			  'clientid' => $client_id,
			  'nickname' => $config->{device_name}
			 },
			 [{
			   'clientid' => $client_id,
			   'value' => 'yes',
			   'nickname' => $config->{device_name},
			   'function' => 'WOL'
			  }]
			]
	   }
    ;


my $soap = data_section __PACKAGE__, 'soap.xml';
my $codes = decode_json(data_section __PACKAGE__, 'codes.json');

$\ = "\n";

if (defined $opt->list) {
    # print join ', ', sort keys %$codes;
    if ($opt->list) {
	my $re = $opt->list;
	print join ', ', grep { /$re/i } keys %$codes;
    } else {
	print join ', ', sort keys %$codes;
    }
    exit;
}

if (defined $opt->power) {
    my $url = sprintf('http://%s/sony/system', '192.168.1.128');
    print $url;

    my $payload = {
		   'method' =>  'getPowerStatus',
		   'params' => [],
		   'id' =>  10,
		   'version' => '1.0'
		  };

    my $tx = $ua->build_tx(POST => $url => {Accept => '*/*'} => json => $payload);
    $ua->start_p($tx)
	->then(sub {
		   my $tx = shift;
		   print $tx->res->body;
		   Mojo::IOLoop->stop;
	       })
	->catch();
    
}

my $command = $ARGV[0];


my ($command) = grep { /^$command$/i } keys %$codes;

$soap = sprintf $soap, $codes->{$command};

# print $soap;

my $tx = $ua->post('http://192.168.1.128/sony/accessControl', json => $data);

# print dumper $ua->cookie_jar;

my $auth = [ map { $_->value } grep { $_->name eq 'auth' } @{$tx->res->cookies} ]->[0] || die;

my $url = 'http://192.168.1.128/sony/IRCC';

$tx = $ua->build_tx(POST => $url => {Accept => '*/*'} => $soap);

$tx->req->cookies({ name => 'auth', value => $auth });
$tx->req->headers->header('SOAPAction' => '"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"');

$ua->start_p($tx)
    ->then(sub {
	       my $tx = shift;
	       print $tx->res->body;
	       Mojo::IOLoop->stop;
	   })
    ->catch();

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
    
__DATA__
@@soap.xml
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
<IRCCCode>%s</IRCCCode>
</u:X_SendIRCC>
</s:Body>
</s:Envelope>
@@codes.json
{
  "Num1": "AAAAAQAAAAEAAAAAAw==",
  "Num2": "AAAAAQAAAAEAAAABAw==",
  "Num3": "AAAAAQAAAAEAAAACAw==",
  "Num4": "AAAAAQAAAAEAAAADAw==",
  "Num5": "AAAAAQAAAAEAAAAEAw==",
  "Num6": "AAAAAQAAAAEAAAAFAw==",
  "Num7": "AAAAAQAAAAEAAAAGAw==",
  "Num8": "AAAAAQAAAAEAAAAHAw==",
  "Num9": "AAAAAQAAAAEAAAAIAw==",
  "Num0": "AAAAAQAAAAEAAAAJAw==",
  "Num11": "AAAAAQAAAAEAAAAKAw==",
  "Num12": "AAAAAQAAAAEAAAALAw==",
  "Enter": "AAAAAQAAAAEAAAALAw==",
  "GGuide": "AAAAAQAAAAEAAAAOAw==",
  "ChannelUp": "AAAAAQAAAAEAAAAQAw==",
  "ChannelDown": "AAAAAQAAAAEAAAARAw==",
  "VolumeUp": "AAAAAQAAAAEAAAASAw==",
  "VolumeDown": "AAAAAQAAAAEAAAATAw==",
  "Mute": "AAAAAQAAAAEAAAAUAw==",
  "TvPower": "AAAAAQAAAAEAAAAVAw==",
  "Audio": "AAAAAQAAAAEAAAAXAw==",
  "MediaAudioTrack": "AAAAAQAAAAEAAAAXAw==",
  "Tv": "AAAAAQAAAAEAAAAkAw==",
  "Input": "AAAAAQAAAAEAAAAlAw==",
  "TvInput": "AAAAAQAAAAEAAAAlAw==",
  "TvAntennaCable": "AAAAAQAAAAEAAAAqAw==",
  "WakeUp": "AAAAAQAAAAEAAAAuAw==",
  "PowerOff": "AAAAAQAAAAEAAAAvAw==",
  "Sleep": "AAAAAQAAAAEAAAAvAw==",
  "Right": "AAAAAQAAAAEAAAAzAw==",
  "Left": "AAAAAQAAAAEAAAA0Aw==",
  "SleepTimer": "AAAAAQAAAAEAAAA2Aw==",
  "Analog2": "AAAAAQAAAAEAAAA4Aw==",
  "TvAnalog": "AAAAAQAAAAEAAAA4Aw==",
  "Display": "AAAAAQAAAAEAAAA6Aw==",
  "Jump": "AAAAAQAAAAEAAAA7Aw==",
  "PicOff": "AAAAAQAAAAEAAAA+Aw==",
  "PictureOff": "AAAAAQAAAAEAAAA+Aw==",
  "Teletext": "AAAAAQAAAAEAAAA/Aw==",
  "Video1": "AAAAAQAAAAEAAABAAw==",
  "Video2": "AAAAAQAAAAEAAABBAw==",
  "AnalogRgb1": "AAAAAQAAAAEAAABDAw==",
  "Home": "AAAAAQAAAAEAAABgAw==",
  "Exit": "AAAAAQAAAAEAAABjAw==",
  "PictureMode": "AAAAAQAAAAEAAABkAw==",
  "Confirm": "AAAAAQAAAAEAAABlAw==",
  "Up": "AAAAAQAAAAEAAAB0Aw==",
  "Down": "AAAAAQAAAAEAAAB1Aw==",
  "ClosedCaption": "AAAAAgAAAKQAAAAQAw==",
  "Component1": "AAAAAgAAAKQAAAA2Aw==",
  "Component2": "AAAAAgAAAKQAAAA3Aw==",
  "Wide": "AAAAAgAAAKQAAAA9Aw==",
  "EPG": "AAAAAgAAAKQAAABbAw==",
  "PAP": "AAAAAgAAAKQAAAB3Aw==",
  "TenKey": "AAAAAgAAAJcAAAAMAw==",
  "BSCS": "AAAAAgAAAJcAAAAQAw==",
  "Ddata": "AAAAAgAAAJcAAAAVAw==",
  "Stop": "AAAAAgAAAJcAAAAYAw==",
  "Pause": "AAAAAgAAAJcAAAAZAw==",
  "Play": "AAAAAgAAAJcAAAAaAw==",
  "Rewind": "AAAAAgAAAJcAAAAbAw==",
  "Forward": "AAAAAgAAAJcAAAAcAw==",
  "DOT": "AAAAAgAAAJcAAAAdAw==",
  "Rec": "AAAAAgAAAJcAAAAgAw==",
  "Return": "AAAAAgAAAJcAAAAjAw==",
  "Blue": "AAAAAgAAAJcAAAAkAw==",
  "Red": "AAAAAgAAAJcAAAAlAw==",
  "Green": "AAAAAgAAAJcAAAAmAw==",
  "Yellow": "AAAAAgAAAJcAAAAnAw==",
  "SubTitle": "AAAAAgAAAJcAAAAoAw==",
  "CS": "AAAAAgAAAJcAAAArAw==",
  "BS": "AAAAAgAAAJcAAAAsAw==",
  "Digital": "AAAAAgAAAJcAAAAyAw==",
  "Options": "AAAAAgAAAJcAAAA2Aw==",
  "Media": "AAAAAgAAAJcAAAA4Aw==",
  "Prev": "AAAAAgAAAJcAAAA8Aw==",
  "Next": "AAAAAgAAAJcAAAA9Aw==",
  "DpadCenter": "AAAAAgAAAJcAAABKAw==",
  "CursorUp": "AAAAAgAAAJcAAABPAw==",
  "CursorDown": "AAAAAgAAAJcAAABQAw==",
  "CursorLeft": "AAAAAgAAAJcAAABNAw==",
  "CursorRight": "AAAAAgAAAJcAAABOAw==",
  "ShopRemoteControlForcedDynamic": "AAAAAgAAAJcAAABqAw==",
  "FlashPlus": "AAAAAgAAAJcAAAB4Aw==",
  "FlashMinus": "AAAAAgAAAJcAAAB5Aw==",
  "DemoMode": "AAAAAgAAAJcAAAB8Aw==",
  "Analog": "AAAAAgAAAHcAAAANAw==",
  "Mode3D": "AAAAAgAAAHcAAABNAw==",
  "DigitalToggle": "AAAAAgAAAHcAAABSAw==",
  "DemoSurround": "AAAAAgAAAHcAAAB7Aw==",
  "*AD": "AAAAAgAAABoAAAA7Aw==",
  "AudioMixUp": "AAAAAgAAABoAAAA8Aw==",
  "AudioMixDown": "AAAAAgAAABoAAAA9Aw==",
  "PhotoFrame": "AAAAAgAAABoAAABVAw==",
  "Tv_Radio": "AAAAAgAAABoAAABXAw==",
  "SyncMenu": "AAAAAgAAABoAAABYAw==",
  "Hdmi1": "AAAAAgAAABoAAABaAw==",
  "Hdmi2": "AAAAAgAAABoAAABbAw==",
  "Hdmi3": "AAAAAgAAABoAAABcAw==",
  "Hdmi4": "AAAAAgAAABoAAABdAw==",
  "TopMenu": "AAAAAgAAABoAAABgAw==",
  "PopUpMenu": "AAAAAgAAABoAAABhAw==",
  "OneTouchTimeRec": "AAAAAgAAABoAAABkAw==",
  "OneTouchView": "AAAAAgAAABoAAABlAw==",
  "DUX": "AAAAAgAAABoAAABzAw==",
  "FootballMode": "AAAAAgAAABoAAAB2Aw==",
  "iManual": "AAAAAgAAABoAAAB7Aw==",
  "Netflix": "AAAAAgAAABoAAAB8Aw==",
  "Assists": "AAAAAgAAAMQAAAA7Aw==",
  "FeaturedApp": "AAAAAgAAAMQAAABEAw==",
  "FeaturedAppVOD": "AAAAAgAAAMQAAABFAw==",
  "GooglePlay": "AAAAAgAAAMQAAABGAw==",
  "ActionMenu": "AAAAAgAAAMQAAABLAw==",
  "Help": "AAAAAgAAAMQAAABNAw==",
  "TvSatellite": "AAAAAgAAAMQAAABOAw==",
  "WirelessSubwoofer": "AAAAAgAAAMQAAAB+Aw==",
  "AndroidMenu": "AAAAAgAAAMQAAABPAw=="
}
