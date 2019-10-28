
use Net::MQTT::Simple;

my $mqtt = Net::MQTT::Simple->new("127.0.0.1");


$mqtt->publish("control" => "S$ARGV[0]");
sleep(1);
$mqtt->publish("control" => "S$ARGV[0]");
$mqtt->disconnect();
