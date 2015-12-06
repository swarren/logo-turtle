#!/usr/bin/env python3

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

import wdoturtle

t = wdoturtle.Turtle()

min_l = 20
levels = 4

def koch(l, tsign):
  if l <= min_l:
    t.forward(l)
    return

  koch(l / 3, tsign * 1)
  if tsign > 0:
    t.right(90)
  else:
    t.left(90)
  koch(l / 3, tsign * -1)
  if tsign > 0:
    t.left(90)
  else:
    t.right(90)
  koch(l / 3, tsign * 1)
  if tsign > 0:
    t.left(90)
  else:
    t.right(90)
  koch(l / 3, tsign * -1)
  if tsign > 0:
    t.right(90)
  else:
    t.left(90)
  koch(l / 3, tsign * 1)

koch(min_l * (3 ** levels), 1)
