# Countersteer in Trackmania

In this project, countersteer means using steering input while the car is in the air to reduce unwanted car-body rotation before landing.

This is different from drift countersteer. The goal is not to catch a slide on the ground. The goal is to correct the car's airborne rotation so the car lands straighter, cleaner, and with less speed loss.

## Air Rotation

When a Trackmania car leaves the ground at an angle, it may keep rotating in the air. This can happen after an angled jump, a bumpy takeoff, a wallride exit, a reactor section, or any transition where the car is not aligned with the road.

If the car keeps rotating too much, the landing becomes unstable. The car can land sideways, bounce, lose grip, or scrub speed because the wheels touch down at the wrong angle.

## What Countersteer Does

Countersteer applies steering opposite to the current airborne rotation of the car body. It is not based on the steering wheel angle; it is based on which way the car itself is rotating.

For example:

- If the car is rotating left in the air, steer right to slow that rotation.
- If the car is rotating right in the air, steer left to slow that rotation.

The purpose is to cancel or reduce the spin before the wheels touch the ground. A good countersteer makes the car land closer to the direction it needs to face, but the input decision itself comes from the sign of the current yaw rotation.

## Why It Matters

Good airborne countersteer can:

- make landings more stable
- reduce sideways landings
- prevent unnecessary bounces
- keep more speed after landing
- help align the car for the next turn or checkpoint

The timing and amount of steering matter. Holding the opposite steer for too long can overcorrect the car and create rotation in the other direction. Often the best input is a short correction, then releasing or adjusting as the car becomes aligned.

## Simple Rule

Watch the direction the car is rotating in the air, then steer the other way until the rotation slows down enough for a clean landing.
