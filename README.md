# Countersteer Advisor

Openplanet overlay plugin for Trackmania 2020 / Trackmania Next.

The plugin follows `countersteer.md`: it estimates the car's sideways/yaw rotation from the vehicle orientation basis and, while airborne, shows the opposite steering cue.

- rotating right -> `STEER LEFT`
- rotating left -> `STEER RIGHT`
- rotation below the threshold -> `CENTER`

The cue is sign-based: steer opposite the detected yaw rate until the rotation slows or stops. Detection is based on vehicle body orientation changing over time, not wheel angle or steering input. The current steering input is only used to label the cue as `STEER` or `HOLD`.

It does not rewrite or inject steering input; it is an in-game visual advisor for timing the short countersteer correction before landing.

## Files

- `info.toml`: Openplanet plugin manifest.
- `main.as`: AngelScript implementation.
- `countersteer.md`: project definition of countersteer behavior.
