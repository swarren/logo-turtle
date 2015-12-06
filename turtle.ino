# Copyright (c) 2014-2015, Stephen Warren
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.import random

#include <Servo.h>

#define DEBUG 1
#define ARSIZE(_x_) (sizeof (_x_) / sizeof ((_x_)[0]))

static inline void debug(const char *msg) {
#if DEBUG
  Serial.println(msg);
#endif
}
  
const int motor_en_n = 13;
const int m0 = 12;
const int m1 = 11;
const int servo_pos_b = 10;
const int servo_pos_a = 9;
const int sleep_n = 8;
const int motor_step = 7;
const int motor_l_dir = 6;
const int motor_r_dir = 5;

const int servo_offset = 20;
const int servo_range = 45;

Servo pen;

void setup() {
  Serial.begin(57600);

  pinMode(motor_en_n, OUTPUT);
  digitalWrite(motor_en_n, HIGH);
  pinMode(sleep_n, OUTPUT);
  digitalWrite(sleep_n, LOW);

  pinMode(motor_step, OUTPUT);
  digitalWrite(motor_step, LOW);
  pinMode(motor_l_dir, OUTPUT);
  digitalWrite(motor_l_dir, LOW);
  pinMode(motor_r_dir, OUTPUT);
  digitalWrite(motor_r_dir, LOW);

  pinMode(m0, OUTPUT);
  digitalWrite(m1, LOW);
  pinMode(m1, OUTPUT);
  digitalWrite(m1, LOW);

  pen.write(180 - (servo_range + servo_offset));
  pen.attach(servo_pos_a);

  Serial.println("Booted");
}

const int step_pulse_width_us = 10000;
const int step_gap_us = 5000;

const int STEP_FWD = 0;
const int STEP_BWD = 1;
const int STEP_L = 2;
const int STEP_R = 3;

const int DIR_L = 0;
const int DIR_R = 1;

const int dirs[][2] = {
  [STEP_FWD] = {[DIR_L] = HIGH, [DIR_R] = LOW},
  [STEP_BWD] = {[DIR_L] = LOW,  [DIR_R] = HIGH},
  [STEP_L]   = {[DIR_L] = HIGH, [DIR_R] = HIGH},
  [STEP_R]   = {[DIR_L] = LOW,  [DIR_R] = LOW},
};

void select_dir(int dir) {
  digitalWrite(motor_l_dir, dirs[dir][DIR_L]);
  digitalWrite(motor_r_dir, dirs[dir][DIR_R]);
}

void step(void) {
  digitalWrite(motor_step, HIGH);
  delayMicroseconds(step_pulse_width_us);
  digitalWrite(motor_step, LOW);
  delayMicroseconds(step_gap_us);
}

void steps(int dir, int count) {
  int i;

  select_dir(dir);
  for (i = 0; i < count; i++)
    step();
}

int do_move(int dir, char *params) {
  unsigned long count;
  char *extra;

  count = strtoul(params, &extra, 0);
  if (extra && *extra) {
    debug("params after value");
    return 1;
  }
  if (!count) {
    debug("count==0");
    return 1;
  }

  steps(dir, count);

  return 0;
}

int do_f(char *params) {
  return do_move(STEP_FWD, params);
}

int do_b(char *params) {
  return do_move(STEP_BWD, params);
}

int do_l(char *params) {
  return do_move(STEP_L, params);
}

int do_r(char *params) {
  return do_move(STEP_R, params);
}

int do_u(char *params) {
  if (*params) {
    debug("params specified");
    return 1;
  }

  pen.write(180 - (servo_range + servo_offset));

  return 0;
}

int do_d(char *params) {
  if (*params) {
    debug("params specified");
    return 1;
  }

  pen.write(180 - servo_offset);

  return 0;
}

int do_0(char *params) {
  if (*params) {
    debug("params specified");
    return 1;
  }

  digitalWrite(motor_en_n, HIGH);
  digitalWrite(sleep_n, LOW);

  return 0;
}

int do_1(char *params) {
  if (*params) {
    debug("params specified");
    return 1;
  }

  digitalWrite(motor_en_n, LOW);
  digitalWrite(sleep_n, HIGH);

  return 0;
}

#define STEP_FLOAT 0
#define STEP_LOW   2
#define STEP_HIGH  3

const struct {
  const char *size;
  bool m0;
  bool m1;
} step_table[] = {
  {"1",  STEP_LOW,   STEP_LOW},
  {"2",  STEP_HIGH,  STEP_LOW},
  {"4",  STEP_FLOAT, STEP_LOW},
  {"8",  STEP_LOW,   STEP_HIGH},
  {"16", STEP_HIGH,  STEP_HIGH},
  {"32", STEP_FLOAT, STEP_HIGH},
};

int do_s(char *params) {
  int i;

  for (i = 0; i < ARSIZE(step_table); i++) {
    if (!strcmp(params, step_table[i].size)) {
      break;
    }
  }
  if (i == ARSIZE(step_table)) {
    return 1;
  }

  if (step_table[i].m0 == STEP_FLOAT) {
    pinMode(m0, INPUT);
  } else {
    pinMode(m0, OUTPUT);
    digitalWrite(m1, (step_table[i].m0 == STEP_HIGH) ? HIGH : LOW);
  }
  if (step_table[i].m1 == STEP_FLOAT) {
    pinMode(m1, INPUT);
  } else {
    pinMode(m1, OUTPUT);
    digitalWrite(m1, (step_table[i].m1 == STEP_HIGH) ? HIGH : LOW);
  }

  return 0;
}

typedef int (*cmd_func)(char *params);
const struct {
  char cmd;
  cmd_func func;
} cmdtable[] = {
  {'f', do_f},
  {'b', do_b},
  {'l', do_l},
  {'r', do_r},
  {'u', do_u},
  {'d', do_d},
  {'0', do_0},
  {'1', do_1},
  {'s', do_s},
};

void loop() {
  char buf[32];
  int len, i, ret;

  len = Serial.readBytesUntil('\n', buf, sizeof(buf));
  if (!len)
    return;
  if (len >= sizeof(buf))
    len = sizeof(buf) - 1;
  buf[len] = '\0';

#if DEBUG
  Serial.print("<");
  Serial.print(buf);
  Serial.println(">");
#endif

  for (i = 0; i < ARSIZE(cmdtable); i++) {
    if (buf[0] == cmdtable[i].cmd) {
      ret = cmdtable[i].func(&buf[1]);
      if (ret)
        Serial.println("ERROR");
      else
        Serial.println("OK");
      return;
    }
  }
  debug("Unknown cmd");
  Serial.println("ERROR");
}
