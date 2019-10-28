#!/usr/bin/perl 

##########################################################################
##    ESP8266 + Rader Alarm
##    Copyright (C) 2019  Wan Leung Wong me@wanleung.com
##
##    This program is free software: you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.


use warnings;
use strict;
use Net::MQTT::Simple;

my $mqtt = Net::MQTT::Simple->new("127.0.0.1");


$mqtt->publish("control" => "S$ARGV[0]");
sleep(1);
$mqtt->publish("control" => "S$ARGV[0]");
$mqtt->disconnect();
