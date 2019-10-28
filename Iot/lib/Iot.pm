package Iot;
use Dancer2;
use Data::Dumper;
use Dancer2::Plugin::REST;
use Net::MQTT::Simple;
use Cache::Memcached;
 
prepare_serializer_for_format;

my $mqtt = Net::MQTT::Simple->new("127.0.0.1");
my $memd = new Cache::Memcached {
  'servers' => ["127.0.0.1:11211"],
  'debug' => 0,
  'compress_threshold' => 10_000,
};

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => { 'title' => 'Iot' };
};

post '/bot/:chatid/hook.:format' => sub {
    #my %body_parameters = params('body');
    #print Dumper(\%body_parameters);
    my $update_id = body_parameters->get('update_id');
    my $message = body_parameters->get('message');
    print "$update_id\n";
    print Dumper($message);

    my $last_msg_id = $memd->get("last_msg_id");

    ( $last_msg_id < $message->{'message_id'} ) or status_ok({"status" => "ok"});

    if ($message->{'entities'} and $message->{'entities'}->[0]->{'type'} eq 'bot_command') {
        print "bot_command\n";
        my $text = $message->{'text'};
        my ($command, $param) = split(' ', $text);
        $param or $param = 0;
        if ($command eq '/alarmon') {
            $mqtt->publish("control" => "B1");
            $mqtt->publish("control" => "B1");
        }
        if ($command eq '/alarmoff') {
            $mqtt->publish("control" => "B0");
            $mqtt->publish("control" => "B0");
        }
        if ($command eq '/silentoff') {
            $mqtt->publish("control" => "S0");
            $mqtt->publish("control" => "S0");
        }
        if ($command eq '/silenton') {
            $mqtt->publish("control" => "S1");
            $mqtt->publish("control" => "S1");
        }
        if ($command eq '/status') {
            $mqtt->publish("control" => "L");
        }
        if ($command eq '/alertoff') {
            $mqtt->publish("control" => "ZOFF");
        }
        if ($command eq '/alerton') {
            $mqtt->publish("control" => "ZON");
        }
        if ($command eq '/reset') {
            if ($param) {
                $mqtt->publish("control" => "ZON");
                $mqtt->publish("control" => "ZON");
                $mqtt->publish("control" => "S1");
                $mqtt->publish("control" => "S1");
                $mqtt->publish("control" => "B0");
                $mqtt->publish("control" => "B0");
                $mqtt->publish("control" => "L");
            } else {
                $mqtt->publish("control" => "ZON");
                $mqtt->publish("control" => "ZON");
                $mqtt->publish("control" => "S0");
                $mqtt->publish("control" => "S0");
                $mqtt->publish("control" => "B0");
                $mqtt->publish("control" => "B0");
                $mqtt->publish("control" => "L");
            }
        }

    } else {
        print "message\n";
    }

    $last_msg_id = $message->{'message_id'};
    $memd->set("last_msg_id", $last_msg_id);
    status_ok({"status" => "ok"});
};

true;
