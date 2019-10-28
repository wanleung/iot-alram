/*
    ESP8266 + Rader Alarm
    Copyright (C) 2019  Wan Leung Wong me@wanleung.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
*/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

#include "DHTesp.h"

// Update these with values suitable for your network.

const char* ssid = "...";
const char* password = "...";
const char* mqtt_server = "...";

const long utcOffsetInSeconds = 3600;

const int pinBuzzer = 4;
const int pinMotionSensor = 2;
const int pinSlientLED = 14;
const int pinAlertLED = 12;
const int pinNormalLED = 15;

WiFiClient espClient;
PubSubClient client(espClient);
DHTesp dht;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds);
long lastMsg = 0;
long lastTmp = 0;
char msg[50];
char str_temp[6];
char str_hum[6];
int value = 0;
int in_motion = 0;
int status_silent = 0;
int status_in_motion = 0;
long last_trigger = 0;
int motion_count = 0;

void setup_wifi() {

  delay(10);
  // We start by connecting to a WiFi network
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  randomSeed(micros());

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  if ((char)payload[0] == 'B') {
    if ((char)payload[1] == '1') {
      alertOn();
    } else {
      alertOff();
      snprintf(msg, 50, "A:0");
      client.publish("iot", msg);
      digitalWrite(pinAlertLED, LOW);
    }
  }

  if ((char)payload[0] == 'S') {
    if ((char)payload[1] == '1') {
      silentOn();
    } else {
      silentOff();
      snprintf(msg, 50, "S:0");
      client.publish("iot", msg);
    }
  }

  if ((char)payload[0] == 'L') {
    delay(dht.getMinimumSamplingPeriod());

    float humidity = dht.getHumidity();
    float temperature = dht.getTemperature();
    dtostrf(temperature, 4, 2, str_temp);
    dtostrf(humidity, 4, 2, str_hum);
    snprintf(msg, 50, "STATUS:T=%s:H=%s:M=%ld:m=%ld:S=%ld", str_temp, str_hum, status_in_motion, in_motion, status_silent);
    client.publish("iot", msg);
  }

}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Create a random client ID
    String clientId = "ESP8266Client-";
    clientId += String(random(0xffff), HEX);
    // Attempt to connect
    if (client.connect(clientId.c_str(), "mqtt-test", "testing123456")) {
      Serial.println("connected");
      // Once connected, publish an announcement...
      client.publish("iot", "MSG:hello world");
      // ... and resubscribe
      client.subscribe("control");
      timeClient.begin();
      //timeClient.update();
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void setup() {
  pinMode(pinBuzzer, OUTPUT);
  pinMode(pinMotionSensor, INPUT);
  pinMode(pinSlientLED, OUTPUT);
  pinMode(pinAlertLED, OUTPUT);
  pinMode(pinNormalLED, OUTPUT);
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
  dht.setup(5, DHTesp::DHT11);
  digitalWrite(pinBuzzer, LOW);
  digitalWrite(pinAlertLED, LOW);
  digitalWrite(pinNormalLED, HIGH);


  delay(dht.getMinimumSamplingPeriod());

  float humidity = dht.getHumidity();
  float temperature = dht.getTemperature();
  dtostrf(temperature, 4, 2, str_temp);
  dtostrf(humidity, 4, 2, str_hum);
}

void alertOn() {
  if (status_silent == 0) {
    digitalWrite(pinBuzzer, HIGH);
  }
  digitalWrite(pinAlertLED, HIGH);
  status_in_motion = 1;
}

void alertOff() {
  digitalWrite(pinBuzzer, LOW);
  digitalWrite(pinAlertLED, LOW);
  status_in_motion = 0;
}

void silentOn() {
  status_silent = 1;
  digitalWrite(pinBuzzer, LOW);
}

void silentOff() {
  status_silent = 0;
  if (status_in_motion == 1) {
    digitalWrite(pinBuzzer, HIGH);
  }
}

void loop() {

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  long now = millis();
  if (now - lastTmp > 10000) {
    lastTmp = now;
    ++value;
    delay(dht.getMinimumSamplingPeriod());

    float humidity = dht.getHumidity();
    float temperature = dht.getTemperature();

    Serial.print(dht.getStatusString());
    Serial.print("\t");
    Serial.print(humidity, 1);
    Serial.print("\t\t");
    Serial.println(temperature, 1);
    dtostrf(temperature, 4, 2, str_temp);
    dtostrf(humidity, 4, 2, str_hum);
    snprintf(msg, 50, "TEMP:T=%s:H=%s", str_temp, str_hum);
    Serial.print("Publish message: ");
    Serial.println(msg);
    client.publish("iot", msg);
  }

  if (now - lastMsg > 2000) {
    lastMsg = now;
    ++value;
    in_motion = digitalRead(pinMotionSensor);
    if (in_motion == HIGH) {
      if (motion_count++ > 3) {
        if (status_in_motion == 0) {
          last_trigger = now;
          snprintf(msg, 50, "ALERT:%ld", last_trigger);
          client.publish("iot", msg);
        } else {
          if (((now - last_trigger) - 60000 > 0) ) {
            snprintf(msg, 50, "ALERTF:%ld", (now - last_trigger));
            client.publish("iot", msg);        
          }
        }
        alertOn();
      } 
    } else {
      motion_count = 0;
    }
    snprintf(msg, 50, "MOTION:%ld", in_motion);
    client.publish("iot", msg);
  }
  digitalWrite(pinSlientLED, status_silent);
  digitalWrite(pinNormalLED, (status_silent==0)?1:0);
}
