// Copyright (c) 2014-2015, Stephen Warren
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

// Configuration

motor_face_size = 35 + .5;
motor_length = 26 + 2; // I think Pololu's length figure includes the 2mm circular extrusion at the front?
motor_circ_extrude_diam = 22 + 1;
motor_mount_dist = 26;

guide_radius = 20;
guide_width = 2.54;
guide_slot_width_fudge = 1.1;
guide_slot_wall_width = 2.54;
guide_height = 20;

motor_wall_thick = 2.54;
motor_pen_guide_spacing = 2.54 * 3;
motor_spacing = (guide_radius + motor_pen_guide_spacing) * 2;

servo_wall_thick = 2.54;
servo_top_to_bottom_of_tabs = 9.35 + 1; // 1==fudge
servo_top_to_bottom = 9.35 + 26.67 + 1; // 1==fudge
servo_side_to_side = 39.88 + 1; // 1==fudge
servo_side_to_side_inc_tabs = 52.84 + 1; // 1==fudge
servo_tab_width = (servo_side_to_side_inc_tabs - servo_side_to_side) / 2;
servo_tab_height = 19.82;
servo_tab_thick = 2.54 * 3;
servo_tab_thick_extra = 1.5;
servo_tab_hole_spacing = 10.17;
servo_tab_hole_offset = (13.47 - 9.66) - (servo_tab_width / 2);
servo_tab_hole_diam = 3;

chassis_thick = 2.54;
chassis_width_by_motors = 2 * (motor_length + motor_wall_thick) + motor_spacing;
chassis_width_by_servo = 2 * (servo_side_to_side_inc_tabs - (servo_tab_width / 2) + servo_tab_thick_extra);
chassis_width = max(chassis_width_by_motors, chassis_width_by_servo);
chassis_end_spacing = 2.54;
bearing_width = 5; // Bearing is 11 on bottom, but nuts on top are only 5
arduino_bearing_back_spacing = 10;
arduino_width = 2.1 * 25.4;
motor_arduino_spacing = 2.54;
chassis_front_length = chassis_end_spacing + arduino_width + motor_arduino_spacing;
chassis_motor_length = motor_face_size + (2 * motor_wall_thick);
motor_servo_spacing = 0;
servo_width = servo_top_to_bottom + (2 * servo_wall_thick);
servo_bearing_back_spacing = 10;
chassis_rear_length = motor_servo_spacing + servo_width;
chassis_length = chassis_front_length + chassis_motor_length + chassis_rear_length;
chassis_xoff = (chassis_length / 2) - (chassis_front_length + (chassis_motor_length / 2));
arduino_xoff = -(((arduino_width + chassis_motor_length) / 2) + motor_arduino_spacing);

// Utilities

module axes() {
  cube([10000, 1, 1], center=true);
  cube([1, 10000, 1], center=true);
  cube([1, 1, 10000], center=true);
}

module bearing_mounts(hole_height)
{
  screw_diam = (0.09 * 25.4) + 0.5; // 0.5==fudge

  translate([0, -(0.53 / 2)* 25.4, 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
  translate([0, (0.53 / 2)* 25.4, 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
}

module arduino_pro_mounts(hole_height, extra_diam)
{
  screw_diam = 3 + extra_diam; // #4 plus fudge

  ard_w = 2.05 * 25.4;
  ard_h = 2.10 * 25.4;
  x_c = -ard_w / 2;
  y_c = -ard_h / 2;

  translate([x_c + (0.1 * 25.4), y_c + (0.1 * 25.4), 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
  translate([x_c + (0.1 * 25.4), y_c + (2 * 25.4), 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
  translate([x_c + (1.95 * 25.4), y_c + (1.4 * 25.4), 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
  translate([x_c + (1.95 * 25.4), y_c + (0.3 * 25.4), 0])
    cylinder(r=screw_diam / 2, h=hole_height, center=true, $fn=12);
}

module tri_right_prism(x, y, z) {
  translate([0, 0, -z / 2])
    linear_extrude(height=z)
      polygon(
        points=[
          [0, 0],
          [x, 0],
          [0, y]
        ],
        paths=[[0, 1, 2, 0]]
      );
}

module stepper_mount(face_size, motor_len, circ_extrude_diam, mount_dist, wall_thick) {
  outer_face_size = face_size + (2 * wall_thick);
  outer_motor_len = motor_len + (2 * wall_thick);
  front_wall_y_center = -((motor_len + wall_thick) / 2);

  translate([0, motor_len / 2 + wall_thick, face_size / 2]) {
    difference() {
      // Walls around all sides except back, completely infilled for now
      cube([outer_face_size, outer_motor_len, outer_face_size], center=true);
      // Motor; remove inside of previous cube
      cube([face_size, motor_len, face_size], center=true);
      // Cut off top half
      translate([0, 0, wall_thick + (face_size / 2)])
        cube([outer_face_size + 0.1, outer_motor_len + 0.1, outer_face_size], center=true);
      // Cut off back wall
      translate([0, motor_len / 2 + wall_thick / 2 + 0.1 / 2, 0])
        cube([outer_face_size + 0.1, wall_thick + 0.2, outer_face_size + 0.1], center=true);
      // Extruded cylinder around shaft
      translate([0, front_wall_y_center, 0])
        rotate([90, 0, 0])
        cylinder(r=circ_extrude_diam / 2, h=wall_thick + 0.2, center=true);
      // Mounting hole
      translate([-mount_dist / 2, front_wall_y_center, -mount_dist / 2])
        rotate([90, 0, 0])
        cylinder(r=3.25 / 2, h=wall_thick + 0.2, center=true, $fn=12);
      // Mounting hole
      translate([mount_dist / 2, front_wall_y_center, -mount_dist / 2])
        rotate([90, 0, 0])
        cylinder(r=3.25 / 2, h=wall_thick + 0.2, center=true, $fn=12);
      // Slope side walls down, eliminate back wall
      translate([0, (motor_len / 2) + 0.1, 0.1])
        rotate([0, 90, 180])
          tri_right_prism(face_size / 2 + 0.2, motor_len + 0.2, outer_face_size + 0.2);
    }
  }
}

module pen_holder_generic(
  chassis_height_from_ground,
  idle_handle_height_from_chassis,
  pen_dist_notch_to_tip,
  pen_diam_below_notch,
  pen_diam_above_notch,
  wall_thick,
  guide_radius,
  guide_width,
  handle_radius,
  handle_width
) {
  min_h_handle = 2.54;

  h_notch_above_chassis = pen_dist_notch_to_tip - chassis_height_from_ground;
  //echo("h_notch_above_chassis", h_notch_above_chassis);
  if (h_notch_above_chassis < 0)
    echo("<b>ERROR:</b> Pen notch below chassis");
  h_below_notch = max(10, h_notch_above_chassis);
  //echo("h_below_notch", h_below_notch);
  h_above_chassis = max(h_notch_above_chassis + 10, idle_handle_height_from_chassis + min_h_handle);
  //echo("h_above_chassis", h_above_chassis);
  h_above_notch = h_above_chassis - h_notch_above_chassis;
  //echo("h_above_notch", h_above_notch);
  h_total = h_below_notch + h_above_notch;
  //echo("h_total", h_total);
  h_handle = h_above_chassis - idle_handle_height_from_chassis;
  //echo("h_handle", h_handle);
  z_handle = (h_total - h_handle) / 2;
  z_pen_above_notch = (h_total - h_above_notch) / 2;

  outer_diam = pen_diam_above_notch + (2 * wall_thick);

  // Support pen by its tip, not by guides;
  // force a gap between chassis and guides at idle
  guide_chassis_gap = 1;
  h_guide = h_above_chassis - guide_chassis_gap;
  z_guide = (h_total - h_guide) / 2;

  rotate([180, 0, 0])
    difference() {
      union() {
        // Main cylinder (wall)
        cylinder(r=outer_diam / 2, h=h_total, center=true, $fn=30);
        // Left guide
        rotate([0, 0, 90])
          translate([guide_radius / 2, 0, z_guide])
          cube([guide_radius, guide_width, h_guide], center=true);
        // Front guide
        rotate([0, 0, 180])
          translate([guide_radius / 2, 0, z_guide])
          cube([guide_radius, guide_width, h_guide], center=true);
        // Right guide
        rotate([0, 0, 270])
          translate([guide_radius / 2, 0, z_guide])
          cube([guide_radius, guide_width, h_guide], center=true);
        // Handle
        translate([handle_radius / 2, 0, z_handle])
          cube([handle_radius, handle_width, h_handle], center=true);
      }
      // Lower (smaller) pen body cutout
      cylinder(r=pen_diam_below_notch / 2, h=h_total + 0.2, center=true, $fn=30);
      // Upper (larger) pen body cutout
      translate([0, 0, z_pen_above_notch + 0.1])
        cylinder(r=pen_diam_above_notch / 2, h=h_above_notch + 0.2, center=true, $fn=30);
    }
}

module servo_tab_mount(hole_offset_mult) {
  hole_1_z = (servo_tab_height - servo_tab_hole_spacing) / 2;
  hole_2_z = hole_1_z + servo_tab_hole_spacing;
  shift = hole_offset_mult < 0 ? -servo_tab_thick_extra : 0;

  difference() {
    // Main mount
    translate([0, shift, -0.1])
      cube([servo_tab_thick, servo_tab_width + servo_tab_thick_extra, servo_tab_height + 0.1]);
    // Bottom screw hole
    translate([servo_tab_thick / 2, (servo_tab_width / 2) + (hole_offset_mult * servo_tab_hole_offset), hole_1_z])
      rotate([0, 90, 0])
      cylinder(r=servo_tab_hole_diam / 2, h=servo_tab_thick + 0.1, center=true, $fn=12);
    // Top screw hole
    translate([servo_tab_thick / 2, (servo_tab_width / 2) + (hole_offset_mult * servo_tab_hole_offset), hole_2_z])
      rotate([0, 90, 0])
      cylinder(r=servo_tab_hole_diam / 2, h=servo_tab_thick + 0.1, center=true, $fn=12);
  }
}

module servo_mounts() {
  // Front wall (mini)
  translate([servo_wall_thick / 2, servo_tab_width + (servo_side_to_side * (3 / 4)), servo_wall_thick / 2])
    cube([servo_wall_thick, servo_side_to_side / 2, servo_wall_thick + 0.1], center=true);
  // Rear wall (mini)
  translate([servo_wall_thick + servo_top_to_bottom + (servo_wall_thick / 2), servo_side_to_side_inc_tabs / 2, servo_wall_thick / 2])
    cube([servo_wall_thick, servo_side_to_side * 0.75, servo_wall_thick + 0.1], center=true);
  // Left side tabs mount
  translate([servo_wall_thick + servo_top_to_bottom_of_tabs, 0, 0])
    servo_tab_mount(hole_offset_mult = -1);
  // Right side tabs mount
  translate([servo_wall_thick + servo_top_to_bottom_of_tabs, servo_side_to_side_inc_tabs - servo_tab_width, 0])
    servo_tab_mount(hole_offset_mult = 1);
}

module chassis() {
  w_guide_slot = guide_width + guide_slot_width_fudge;
  w_guide = w_guide_slot + (2 * guide_slot_wall_width);

  difference() {
    union() {
      // Rear base plate (rounded rectangle)
      hull() {
        // Front left corner
        translate([chassis_xoff - 10, -(chassis_width / 2 - 10), -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Front right corner
        translate([chassis_xoff - 10, chassis_width / 2 - 10, -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Rear left corner
        translate([chassis_xoff + chassis_length / 2 - 10, -(chassis_width / 2 - 10), -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Rear right corner
        translate([chassis_xoff + chassis_length / 2 - 10, chassis_width / 2 - 10, -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
      }
      // Front base plate (rounded rectangle)
      hull() {
        // Front left corner
        translate([chassis_xoff - (chassis_length / 2 - 10), -(chassis_width * 0.3 - 10), -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Front right corner
        translate([chassis_xoff - (chassis_length / 2 - 10), chassis_width * 0.3 - 10, -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Read left corner
        translate([chassis_xoff - 10, -(chassis_width * 0.3 - 10), -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
        // Rear right corner
        translate([chassis_xoff - 10, chassis_width * 0.3 - 10, -(chassis_thick / 2 + 0.1)])
          cylinder(r=10, h=chassis_thick + 0.2, $fn=30, center=true);
      }
      // Left convex rounded corner
      difference() {
        translate([chassis_xoff - 25, -(chassis_width * 0.3 + 5), -(chassis_thick / 2 + 0.1)])
          cube([11, 11, chassis_thick + 0.2], center=true);
        translate([chassis_xoff - 30, -(chassis_width * 0.3 + 10), -(chassis_thick / 2 + 0.1)])
          cylinder(r=10.1, h=chassis_thick + 0.4, $fn=30, center=true);
      }
      // Right convex rounded corner
      difference() {
        translate([chassis_xoff - 25, chassis_width * 0.3 + 5, -(chassis_thick / 2 + 0.1)])
          cube([11, 11, chassis_thick + 0.2], center=true);
        translate([chassis_xoff - 30, chassis_width * 0.3 + 10, -(chassis_thick / 2 + 0.1)])
          cylinder(r=10.1, h=chassis_thick + 0.4, $fn=30, center=true);
      }
      // Arduino standoffs
      translate([arduino_xoff, 0, (3.5 / 2) + 0.1])
        rotate([0, 0, 90])
        arduino_pro_mounts(hole_height=3.5 + 0.2, extra_diam = 4);
      // Left Stepper motor mount
      translate([0, -chassis_width / 2, 0.1])
        stepper_mount(motor_face_size, motor_length, motor_circ_extrude_diam, motor_mount_dist, motor_wall_thick);
      // Right Stepper motor mount
      translate([0, chassis_width / 2, 0.1])
        rotate([0, 0, 180])
        stepper_mount(motor_face_size, motor_length, motor_circ_extrude_diam, motor_mount_dist, motor_wall_thick);
      // Left guide walls
      rotate([0, 0, 90])
        translate([guide_radius / 2, 0, guide_height / 2 + 0.1])
        difference(){
          cube([guide_radius, w_guide, guide_height + 0.2], center=true);
          cube([guide_radius + 0.1, w_guide_slot, guide_height + 0.4], center=true);
        }
      // Front guide walls
      rotate([0, 0, 180])
        translate([guide_radius / 2, 0, guide_height / 2 + 0.1])
        difference(){
          cube([guide_radius, w_guide, guide_height + 0.2], center=true);
          cube([guide_radius + 0.1, w_guide_slot, guide_height + 0.4], center=true);
        }
      // Right guide walls
      rotate([0, 0, 270])
        translate([guide_radius / 2, 0, guide_height / 2 + 0.1])
        difference(){
          cube([guide_radius, w_guide, guide_height + 0.2], center=true);
          cube([guide_radius + 0.1, w_guide_slot, guide_height + 0.4], center=true);
        }
      // Servo mounts
      translate([chassis_motor_length / 2, -(servo_tab_width / 2), 0])
        servo_mounts();
    }
    // Pen hole
    cylinder(r=20 / 2, h=100, center=true, $fn=30);
    // Front bearing mounts
    translate([arduino_xoff - arduino_bearing_back_spacing, 0, (-chassis_thick / 2)])
      bearing_mounts(hole_height=chassis_thick + 0.2);
    // Arduino mounts
    translate([arduino_xoff, 0, 0])
      rotate([0, 0, 90])
      arduino_pro_mounts(hole_height=chassis_thick * 5, extra_diam = 0);
    // Rear bearing mounts
    translate([(chassis_motor_length / 2) + motor_servo_spacing + servo_width - servo_bearing_back_spacing, 0, (-chassis_thick / 2)])
      rotate([0, 0, 90])
      bearing_mounts(hole_height=chassis_thick + 0.2);
    // TODO: Rounded corners
  }
}

module pen_holder_unbranded() {
  pen_holder_generic(
    chassis_height_from_ground = 17,
    idle_handle_height_from_chassis = 10,
    pen_dist_notch_to_tip = 22,
    pen_diam_below_notch = 10.2 + 1, // measured + fudge
    pen_diam_above_notch = 12.1 + 1, // measured + fudge
    wall_thick = 2.54 / 2,
    guide_radius = guide_radius,
    guide_width = guide_width,
    handle_radius = 18,
    handle_width = 2.54 * 3
  );
}

module pen_holder_sharpie_fat() {
  pen_holder_generic(
    chassis_height_from_ground = 17,
    idle_handle_height_from_chassis = 10,
    pen_dist_notch_to_tip = 32,
    pen_diam_below_notch = 10.7 + 1, // measured + fudge
    pen_diam_above_notch = 12.2 + 1, // measured + fudge
    wall_thick = 2.54 / 2,
    guide_radius = guide_radius,
    guide_width = guide_width,
    handle_radius = 18,
    handle_width = 2.54 * 3
  );
}

// Design

//axes(); // Debug

intersection() {
  chassis();
  // Limit to: just pen guides:
  //translate([-5, 0, 0]) cube([35, 42, 60], center=true);
  // Limit to: Motor mounts, pen guides:
  //cube([45, 200, 60], center=true);
  // Limit to: Servo mounts, edge of motor mount
  //translate([40, 25, 0]) cube([45, 60, 60], center=true);
}

//pen_holder_unbranded();
//pen_holder_sharpie_fat();
//arduino_pro_mounts(hole_height=chassis_thick + 0.2);
//servo_mounts();
