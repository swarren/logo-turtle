# "LOGO" Turtle

When I was a kid, probably the first programming language I learned was
[LOGO](https://en.wikipedia.org/wiki/Logo_(programming_language)). It was/is
intended as a teaching language, with an emphasis on commands that draw shapes
on screen, as a way to tie programming to the real world. Some lucky people
had a device (a "turtle") connected to their computer which would move around
with a pen attached and physically draw the on-screen shape on paper. My
school did have a turtle for their BBC micro, but I don't recall it working, or
perhaps us kids simply weren't allowed to use it! Since then, I've long wanted
to have my own turtle. So around Christmas 2014, I hacked one together myself.

# Components

- 3D-printed chassis. Designed in OpenSCAD; see `turtle.scad`.
- Arduino Pro (Uno) for motor/servo control. Code is in `turtle.ino`.
- ESP8266 for WiFi to UART bridge, for communication to the Arduino. Code is
  in `turtle-esp8266.ino`; this uses the ESP8266 Arduino port for simplicity.
- Custom Arduino shield to mount the ESP8266 and motor driver boards; see
  `turtle.brd`. I sent this to http://oshpark.com/ for fabrication.
- A bunch of hardware for Pololu, Sparkfun, and Amazon.
- Python code to send commands to the Turtle. See `*.py` in this directory.

# Apologies

A lot of this project is rather hacked together and unclean. Everything works
pretty well, but the code isn't that well written or organized. The OpenSCAD
model in particular was only my third use of OpenSCAD and much larger than
anything I'd done before, and I put little thought into code formatting,
modularity, or cleanliness.

# Hardware BOM

Here's a list of the hardware I used:

- 2x Stepper Motor: Bipolar, 200 Steps/Rev, 35×26mm, 7.4V, 0.28 A/Phase.
  https://www.pololu.com/product/1207
- 2x DRV8834 Low-Voltage Stepper Motor Driver Carrier.
  https://www.pololu.com/product/2134
- 2x Pololu Wheel 70×8mm Pair - Yellow.
  https://www.pololu.com/product/1427
- Pololu Universal Aluminum Mounting Hub for 5mm Shaft, #4-40 Holes (2-Pack).
  https://www.pololu.com/product/1203
- Machine Screw: #4-40, 1/2" Length, Phillips (25-pack),
  https://www.pololu.com/product/1962
- Machine Hex Nut: #4-40 (25-pack).
  https://www.pololu.com/product/1068
- 2x Ball caster. https://www.pololu.com/product/951
- 1x Hitec RCD 31430S HS-430BH Deluxe High Voltage Ball Bearing Servo.
  http://www.amazon.com/gp/product/B005M083Z2?psc=1&redirect=true&ref_=oh_aui_detailpage_o00_s00
- 1x Battery charger. https://www.pololu.com/product/2260
- 1x Polymer Lithium Ion Battery - 1000mAh 7.4v.
  https://www.sparkfun.com/products/11855
- 1x Deans Connector - M/F Pair.
  https://www.sparkfun.com/products/11864
- 1x Arduino Stackable Header Kit.
  https://www.sparkfun.com/products/10007
- 1x Voltage Regulator - 3.3V.
  https://www.sparkfun.com/products/526
- 2x Electrolytic Decoupling Capacitors - 100uF/25V.
  Note that the PCB file calls for 1000uF capacitors, but IIRC Sparkfun didn't
  have any of those (or they were out of stock) so I made do with 100uF
  instead.
  https://www.sparkfun.com/products/96
- 1x Electrolytic Decoupling Capacitors - 10uF/25V.
  https://www.sparkfun.com/products/523
- 4x 0.100" (2.54 mm) Female Header: 1x8-Pin, Straight.
  https://www.pololu.com/product/1018
- Various 0.1" male headers I already had, e.g.:
  https://www.pololu.com/product/965
- 2x 0.1" jumper bridges.
- 1x 10K resistor I already had.
- 1x Arduino Pro 3.3V. This one has the required voltage regulator built in:
  https://www.sparkfun.com/products/10914
- 1x ESP-01 module.
  http://www.amazon.com/gp/product/B00O34AGSU?psc=1&redirect=true&ref_=oh_aui_search_detailpage

# Hook-up Notes

The PCB has headers to which you can connect a USB to 3.3v TTL UART adapter.
There are two sets of pins; "Arduino" for programming the Arduino directly,
and "WiFi" for programming the ESP8266. Once everything is programmed, you
can link the Arduino and ESP8266 by placing two jumpers between the Arduino
serial pins and the other pins directly adjacent to that header.

The ESP-01 module plugs into the ESP8266 header. Make sure it sticks out over
the edge of the board, not pointing at the middle of the board.

The motor driver boards plug into the DRV8834 headers.

The stepper motors plug directly into the DRV8834 boards themselves.

The servo plugs into the "Servo A" header, at least with the current code. The
"Servo B" header isn't currently used.

# Things to Improve or Add

The pen lift mechanism needs some improvement. The hole in the piece that
attaches to the pen needs to re-designed for each type of pen I use; some kind
of adjustment mechanism would be useful (set-screws?). The flanges on that
piece should also be longer, and a tighter fit into the chassis, to counter the
pen wobble when the turtle turns. The wobble produces noticeable issues in the
drawn image at corners. Perhaps some kind of conic mount might help this?

The system does not move forward/backward in a perfectly straight line. I'm
not sure if this is because the rubber tires on the wheels don't yield a
perfectly equal and consistent radius, or whether there's some slippage. This
means that closed polygons don't quite close correctly when drawn.
Assuming slippage isn't the issue, some kind of angular calibration is needed
so that the turtle can auto-correct its angle and counter-act this.
Alternatively, ripping out the guts of an optical mouse might allow fully
automatic calibration-less adjustments!

In order to put the ESP8266 into programming mode, a certain GPIO needs to be
pulled down either during power-up or reset. I forgot to put a button onto my
PCB for this pull-down, or ESP8266 reset. The ESP-01 board doesn't have these
either. So, I dead-bugged and hot-glued a jumper onto the ESP-01 for the GPIO
pull-down, and unplugged/plugged the battery to reset it. A future board
revision should add buttons or jumpers to the Arduino shield for this, or
switch to an ESP8266 board that already includes buttons for this purpose.

Since I built the turtle, various new ESP8266 boards have appeared that expose
many more GPIOs. If I designed this again, I'd probably ditch the Arduino and
connect the stepper drivers directly to the ESP8266. I particularly fancy the
Adafruit Huzzah ESP8266 board for this purpose:
https://www.adafruit.com/products/2471.

Did I mention that the OpenSCAD model's code quality is terrible? Still, it
produces a very nice result, so perhaps not a terrible issue.

The ESP8266 and host-side Python software aren't terribly developed. For
example, IP addresses are hard-coded. My original intention was for the
ESP8266 to be configurable much like a Chromecast is, and use MDNS or similar
to announce itself on the network, so that the Python code could find it
automatically. I never got around to this. To do this properly requires IP
multicast support; something that wasn't present in the EPS8266 SDK at least
in January 2015.

Some kind of GUI app might be nice; some kind of special-purpose "IDE" that
allows the user to edit and run their program. This should always draw turtle
output on screen, and optionally also send commands to the turtle. This would
allow testing user programs without wasting paper.

An Android application! I often demo this by manually typing commands into
ConnectBot over telnet, but that can get annoying.
