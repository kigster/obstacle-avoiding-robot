//
// Created by Konstantin Gredeskoul on 7/8/18.
//

#ifndef OBSTACLEAVOIDANCE_OBSTACLEAVOIDANCE_H
#define OBSTACLEAVOIDANCE_OBSTACLEAVOIDANCE_H

void light1(bool on);
void light2(bool on);
void light3(bool on);
void blink1();
void blink2();
void blink3();
unsigned int spaceAhead();
bool navigateWithSonar();
void turnAndCheck();
void checkOnce(uint8_t type, signed short parameter);
void checkTwice(uint8_t type, signed short parameter);
void leftTurn90(uint8_t type, signed short parameter);
void rightTurn90(uint8_t type, signed short parameter);
void goBack();
void turnAround(uint8_t type, signed short parameter);

#endif //OBSTACLEAVOIDANCE_OBSTACLEAVOIDANCE_H
