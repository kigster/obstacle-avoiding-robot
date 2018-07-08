//
// Created by Konstantin Gredeskoul on 7/8/18.
//

#ifndef OBSTACLEAVOIDANCE_H
#define OBSTACLEAVOIDANCE_H

void led_yellow(bool on);
void led_red(bool on);
void led_green(bool on);

unsigned int spaceAhead();

bool navigateWithSonar();
void turnAndCheck();
void goBack();

void checkOnce(uint8_t type, signed short parameter);
void checkTwice(uint8_t type, signed short parameter);
void leftTurn90(uint8_t type, signed short parameter);
void rightTurn90(uint8_t type, signed short parameter);
void turnAround(uint8_t type, signed short parameter);

#endif
