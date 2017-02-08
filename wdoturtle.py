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
# DEALINGS IN THE SOFTWARE.

import pexpect
import sys

_debug_cmds = False
_debug_angle = False

_MICROSTEP = 32
_MICROSTEP_COUNT_MULT = 4 # Why not == _MICROSTEP?

_CALIB_ANGLE = 360
_CALIB_STEPS = 454 * _MICROSTEP_COUNT_MULT

class Turtle(object):
    def __init__(self):
        # FIXME: Need configuration of this:
        self._exp = pexpect.spawnu('netcat 192.168.145.253 23')
        if _debug_cmds: self._exp.logfile = sys.stdout
        self._do_command('s' + str(_MICROSTEP))
        self._heading_angle = 0
        self._heading_steps = 0

    def motors_on(self):
        self._do_command('1')

    def motors_off(self):
        self._do_command('0')

    def pen_up(self):
        self._do_command('u')

    def pen_down(self):
        self._do_command('d')

    def forward(self, distance):
        self._do_command('f' + str(int(distance)))

    def backward(self, distance):
        self._do_command('b' + str(int(distance)))

    def left(self, angle):
        self._turn(-angle)

    def right(self, angle):
        self._turn(angle)

    def turn_left(self, angle):
        self._turn(-angle)

    def turn_right(self, angle):
        self._turn(angle)

    def _turn(self, angle):
        if _debug_angle: print("Turn " + str(angle))
        self._heading_angle += angle
        if _debug_angle: print("Heading: " + str(self._heading_angle))

        new_heading_steps = int((self._heading_angle / _CALIB_ANGLE) *
                                _CALIB_STEPS)
        if _debug_angle: print("Heading Steps: " + str(new_heading_steps))
        step_delta = new_heading_steps - self._heading_steps
        if _debug_angle: print("Step Delta: " + str(step_delta))
        self._heading_steps = new_heading_steps

        if step_delta < 0:
            cmd = 'l'
            step_delta = -step_delta
        else:
            cmd = 'r'
        if _debug_angle: print("Turning: " + cmd)

        # u, f3
        self._do_command(cmd + str(step_delta))
        # b1, d

        if self._heading_angle >= _CALIB_ANGLE:
            self._heading_angle -= _CALIB_ANGLE
            self._heading_steps -= _CALIB_STEPS
        if self._heading_angle <= -_CALIB_ANGLE:
            self._heading_angle += _CALIB_ANGLE
            self._heading_steps += _CALIB_STEPS
        if _debug_angle: print("Mod Angle: " + str(self._heading_angle))

    def _do_command(self, c):
        self._exp.sendline(c)
        self._exp.expect('OK')
