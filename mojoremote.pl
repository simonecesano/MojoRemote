#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Loader qw(data_section find_modules load_class);
use Mojo::JSON qw/decode_json/;
use Mojo::Util qw/dumper/;


my $config = {
	   device_name => 'my device name'
	     };

my $client_id = "my device name:1";

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

my $tx = app->ua->post('http://192.168.1.128/sony/accessControl', json => $data);

my $auth = [ map { $_->value } grep { $_->name eq 'auth' } @{$tx->res->cookies} ]->[0] || die;

print $auth;


get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

post '/command' => sub {
    my $c = shift;
    my $command = $c->req->json->{command};

    $c->render_later;

    my $url = 'http://192.168.1.128/sony/IRCC';

    my $soap = sprintf $soap, $codes->{$command};

    my $ua = $c->app->ua;
    my $tx = $ua->build_tx(POST => $url => {Accept => '*/*'} => $soap);

    $tx->req->cookies({ name => 'auth', value => $auth });
    $tx->req->headers->header('SOAPAction' => '"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"');

    $ua->start_p($tx)
	->then(sub {
		   my $tx = shift;
		   print $tx->res->body;
		   $c->render(text => $command);
	       })
	->catch();


};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'TV remote';
<div class="bar symbol" data-command="WakeUp">&olcir;</div>
<div class="button" data-command="Netflix">&naturals;</div>
<div class="button symbol">&Congruent;</div>
<div class="button symbol" data-command="Hdmi3">&circledcirc;</div>

<div class="button symbol" data-command="Wide">&rect;</div>
<div class="button symbol" data-command="ClosedCaption">&hellip;</div>
<div class="button symbol" data-command="Mute">&osol;</div>


<div class="button symbol" data-command="Home">&#8962;</div>
<div class="button symbol" data-command="CursorUp">&triangle;</div>
<div class="button symbol" data-command="Return">&circlearrowleft;</div>
<div class="button symbol" data-command="CursorLeft">&triangleleft;</div>
<div class="button symbol" data-command="Confirm">&square;</div>
<div class="button symbol" data-command="CursorDown">&triangleright;</div>
<div class="button symbol" data-command="Prev">&blacktriangleleft;&blacktriangleleft;</div>
<div class="button symbol" data-command="CursorDown">&triangledown;</div>
<div class="button symbol" data-command="Next">&blacktriangleright;&blacktriangleright;</div>

<div class="button symbol" data-command="VolumeUp">&triangle;</div>
<div class="button spacer"></div>
<div class="button" data-command="Pause">&#9612;&#9612;</div>
<div class="button symbol" data-command="VolumeDown">&triangledown;</div>
<div class="button spacer"></div>
<div class="button symbol" data-command="Play">&blacktriangleright;</div>
<script src="./ux.js"></script>
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/0.21.1/axios.min.js"
	    integrity="sha512-bZS47S7sPOxkjU/4Bt0zrhEtWx0y0CRkhEp8IckzK+ltifIIE9EMIMTuT/mEzoIMewUINruDBIR/jJnbguonqQ==" crossorigin="anonymous"></script>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"
	    integrity="sha256-4+XzXVhsDmqanXGHaHvgh1gMQKX40OUvDEBTu8JcmNs=" crossorigin="anonymous"></script>  
    <link rel="stylesheet" type="text/css" href="./style.css" media="screen">
  </head>
  <body><%= content %></body>
</html>
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
@@notes.txt
next/prev
forward/rewind
subtitle
stop
