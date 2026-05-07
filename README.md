# Countersteer Advisor

Openplanet overlay plugin for Trackmania 2020 / Trackmania Next.

The plugin follows `countersteer.md`: it estimates the car's sideways/yaw rotation from the vehicle orientation basis and, while airborne, shows the opposite steering cue.

- rotating right -> `STEER LEFT`
- rotating left -> `STEER RIGHT`

The cue is sign-based: steer opposite the detected yaw rate until the rotation slows or stops. Detection is based on vehicle body orientation changing over time, not wheel angle or steering input.

It does not rewrite or inject steering input; it is an in-game visual advisor for timing the short countersteer correction before landing.

## Files

- `info.toml`: Openplanet plugin manifest.
- `main.as`: Openplanet callbacks.
- `settings.as`: constants and Openplanet settings.
- `src/countersteer.as`: airborne yaw and steering recommendation logic.
- `src/state.as`: shared runtime state and reset helpers.
- `src/vehicle.as`: controlled vehicle lookup through `VehicleState`.
- `src/render.as`: overlay rendering.
- `src/math.as`: small vector/math helpers.
- `countersteer.md`: project definition of countersteer behavior.

## Releases

Generated `.op` archives are not tracked in the repository. Push a `v*` tag, for example `v0.3.0`, to run the GitHub Actions workflow and publish `CountersteerAdvisor.op` as a release asset.
