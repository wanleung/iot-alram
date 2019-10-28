#/usr/bin/perl

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
    


use strict;
use warnings;
use Net::MQTT::Simple;
use WWW::Telegram::BotAPI;
use DateTime;

my $api = WWW::Telegram::BotAPI->new (
        token => '....'
    );

my $chat_id = 00000000;

my $count = 0;
my $mqtt = Net::MQTT::Simple->new("127.0.0.1");

my $send_alert = 1;

$mqtt->publish("control" => "Server Hello");
$mqtt->retain( "iot" => "Server Hello");

$mqtt->run(
    #"sensors/+/temperature" => sub {
    #    my ($topic, $message) = @_;
    #    die "The building's on fire" if $message > 150;
    #},
    "#" => sub {
        my ($topic, $message) = @_;
        print "[$topic] $message\n";
        if ($topic eq 'control') {
            if ($message eq 'ZOFF') {
                $send_alert = 0;
            }
            if ($message eq 'ZON') {
                $send_alert = 1;
            }

        }
        if ($topic eq 'iot') {
            my ($cmd, $data) = split(':', $message, 2);
            if ($data) {
                if ($cmd eq 'STATUS') {
                    my @args = split(':', $data);
                    my $temp = 0;
                    my $hum = 0;
                    my $alarm;
                    my $motion;
                    my $sys;
                    my $alert = ($send_alert == 1)?'On':'Off';
                    for my $s (@args) {
                        my ($info, $value) = split('=', $s);
                        if ($info eq 'T') {
                            $temp = $value;
                        }
                        if ($info eq 'H') {
                            $hum = $value;
                        }
                        if ($info eq 'M') {
                            $alarm = $value==1?'Alart':'Normal';
                        }
                        if ($info eq 'm') {
                            $motion = $value==1?'Moving':'No Moving';
                        } 
                        if ($info eq 'S') {
                            $sys = $value==1?'On':'Off';
                        }
                    }
                    $api->sendMessage({
                            chat_id => $chat_id,
                            text => "Temperature: $temp 'C, Humidity: $hum %"
                        }
                    );
                    $api->sendMessage ({
                                chat_id      => $chat_id,
                                    text    => "Alarm = $alarm, Motion = $motion, Silent = $sys, Alert = $alert", 
                                });

                }
                if ($cmd eq 'ALERT') {
                    my $dt   = DateTime->now;   # Stores current date and time as datetime object
                    $dt->set_time_zone( 'Asia/Hong_Kong' );
                    my $date = $dt->ymd;   # Retrieves date as a string in 'yyyy-mm-dd' format
                    my $time = $dt->hms;
                    if ($send_alert == 1) {
                        $api->sendMessage({
                                chat_id => $chat_id,
                                text => "Alert $time"
                            }
                        );
                    }
                    $count = 0;
                
                }
                if ($cmd eq 'ALERTF') {
                    if ($count % 10 == 0) {
                        if ($send_alert == 1) {
                            $api->sendMessage({
                                    chat_id => $chat_id,
                                    text => "Alert after $data"
                                }
                            );
                        }
                    }
                    $count++;
                }
            } 
        }
    },
);
