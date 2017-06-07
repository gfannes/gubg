#include <Arduino.h>

int signaal = 12;
int output = 13;
int sensor = 2;

void setup()
{
	pinMode(signaal, OUTPUT);
	pinMode(output, OUTPUT);
	pinMode(sensor, INPUT);
}

void loop()
{
	digitalWrite(signaal, HIGH);
	digitalWrite(output, digitalRead(sensor));
	delay(1000);
	digitalWrite(signaal, LOW);
	digitalWrite(output, digitalRead(sensor));
	delay(1000);
}