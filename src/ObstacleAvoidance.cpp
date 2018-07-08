/*
 * This example uses HC-SR04 distance sensor to detect obstacles and change course.
 *
 * Dependencies:
 *    Wire
 *    Adafruit_Motor_Shield_V2_Library
 *    BackSeatDriver
 *    BackSeatDriver_DCMotorAdapter
 *    NewPing
 *
 * Created on: Jul 17, 2014
 *
 * Author: Konstantin Gredeskoul
 *
 * © 2014 All rights reserved.  Please see LICENSE.
 *
 */

#include <Arduino.h>
#include <NewPing.h>

#include "ObstacleAvoidance.h"

#define TRIGGER_PIN  13   // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN     12   // Arduino pin tied to echo pin on the ultrasonic sensor.
#define MAX_DISTANCE 100  // Maximum distance we want to ping for (in centimeters). Maximum sensor distance is rated at 400-500cm.

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);

#include <BackSeatDriver_DCMotorAdapter.h>
#include <BackSeatDriver.h>

signed short motorLayout[] = {1, -2, -3, 4};
uint8_t      ledPin1       = 4, ledPin2 = 11, ledPin3 = 8;

#define OBSTACLE_DISTANCE_TURN 40
#define OBSTACLE_DISTANCE_SLOWDOWN 70

BackSeatDriver_DCMotorAdapter *adapter;
BackSeatDriver                *bot;

bool running = true, led1 = false, led2 = false, led3 = false;

static uint8_t        speed              = 100;
static unsigned int   spaceAfterTurn;
static unsigned int   lastSpaceAhead     = 0, x = 0, maneuverSpaceAhead;
static const uint8_t  sonarCheckPeriodMs = 30; // don't check more often than that
static unsigned short lastSonarAtMs      = 0;

// speed can go up to 255
static uint32_t   startMs = 0;
static const bool debug   = true;

char buffer[128];

// blinky shit

void led_yellow(bool on) {
  led1 = on;
  led1 ? digitalWrite(ledPin1, HIGH) : digitalWrite(ledPin1, LOW);
}

void led_red(bool on) {
  led2 = on;
  led2 ? digitalWrite(ledPin2, HIGH) : digitalWrite(ledPin2, LOW);
}

void led_green(bool on) {
  led3 = on;
  led3 ? digitalWrite(ledPin3, HIGH) : digitalWrite(ledPin3, LOW);
}

//_______________________________________________________________________
//
// Sonar Navigation

unsigned int spaceAhead() {
  if (millis() > sonarCheckPeriodMs + lastSonarAtMs) {
    lastSonarAtMs      = millis();
    unsigned int value = sonar.ping() / US_ROUNDTRIP_CM;
    if (debug && value > 0 && value < OBSTACLE_DISTANCE_SLOWDOWN) {
      sprintf(buffer, "spaceAhead is %d", value);
      bot->log(buffer);
    }
    lastSpaceAhead = (value == 0) ? MAX_DISTANCE : value;
  }
  return lastSpaceAhead;
}

bool navigateWithSonar() {
  int distance = spaceAhead();
  maneuverSpaceAhead = 0;
  if (distance <= OBSTACLE_DISTANCE_TURN) {
    turnAndCheck();
    maneuverSpaceAhead = distance;
    led_yellow(true);
    led_red(true);
    led_green(false);
    return true;
  } else if (distance > OBSTACLE_DISTANCE_TURN
             && distance < OBSTACLE_DISTANCE_SLOWDOWN) {
    // reduce speed
    speed = 100 - (OBSTACLE_DISTANCE_SLOWDOWN - distance) / 2;
    led_yellow(true);
    led_red(false);
    led_green(false);
  } else if (distance >= OBSTACLE_DISTANCE_SLOWDOWN) {
    speed = 100;
    led_yellow(false);
    led_red(false);
  }
  return false;
}

void turnAndCheck() {
  signed short angle = (rand() % 2 == 1) ? 45 : -45;
  bot->turn(angle, &checkOnce);
}

void checkOnce(uint8_t type, signed short parameter) {
  signed short angle = (parameter == -45) ? 90 : -90;
  spaceAfterTurn = spaceAhead();
  if (spaceAfterTurn < maneuverSpaceAhead)
    bot->turn(angle, &checkTwice);
}

void checkTwice(uint8_t type, signed short parameter) {
  signed short angle = (parameter == -90) ? -135 : 135;
  spaceAfterTurn = spaceAhead();
  if (spaceAfterTurn < maneuverSpaceAhead)
    bot->turn(angle, NULL);
}

void leftTurn90(uint8_t type, signed short parameter) {
  delay(1000);
  bot->turn(-90, &rightTurn90);
}

void rightTurn90(uint8_t type, signed short parameter) {
  delay(1000);
  bot->turn(90, &leftTurn90);
}

void goBack() {
  bot->goBackward(70, 600, &turnAround);
}

void turnAround(uint8_t type, signed short parameter) {
  bot->turn(180, NULL);
}

//______________________________________________________________

void setup() {
  Serial.begin(9600);
  Serial.println("Racer Starting...");
  srand(millis());

  pinMode(ledPin1, OUTPUT);
  pinMode(ledPin2, OUTPUT);
  pinMode(ledPin3, OUTPUT);

  adapter = new BackSeatDriver_DCMotorAdapter(4, motorLayout);

  bot = new BackSeatDriver(adapter);
  bot->attach();
  bot->debug(true);
  bot->setMovingSpeedPercent(70);
  bot->setTurningDelayCoefficient(6);
  bot->setTurningSpeedPercent(70);

  startMs = millis();
}

void loop() {
  if (!bot->isManeuvering() && running) {
    led_green(true);
    bot->goForward(speed);
    navigateWithSonar();
  }
}

