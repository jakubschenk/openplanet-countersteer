CSceneVehicleVisState@ GetControlledVehicleState()
{
    auto app = cast<CTrackMania>(GetApp());
    if (app is null || app.GameScene is null || app.CurrentPlayground is null) {
        return null;
    }

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground is null || playground.GameTerminals.Length == 0) {
        return null;
    }

    auto terminal = playground.GameTerminals[0];
    if (terminal is null || terminal.UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) {
        return null;
    }

    auto player = cast<CSmPlayer>(terminal.ControlledPlayer);
    if (player is null) {
        return null;
    }

    CSceneVehicleVis@ vis = VehicleState::GetVis(app.GameScene, player);
    if (vis is null || vis.AsyncState is null) {
        return null;
    }

    return vis.AsyncState;
}
