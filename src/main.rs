use bevy::color::palettes::css;
use bevy::input::keyboard::keyboard_input_system;
use bevy::prelude::*;
use bevy_vello::{prelude::*, VelloPlugin};
use log::debug;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(VelloPlugin::default())
        .add_systems(Startup, setup)
        .add_systems(Update, (keyboard_input_system, keyboard_log, detect_keys))
        .add_systems(Startup, setup_ui)
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d::default());
}

fn keyboard_log(keys: Res<ButtonInput<KeyCode>>) {
    debug!("keyboard: {:?}", keys.get_pressed().collect::<Vec<_>>());
}

fn detect_keys(keys: Res<ButtonInput<KeyCode>>, mut exit: EventWriter<AppExit>) {
    if keys.pressed(KeyCode::KeyQ) {
        debug!("GAME terminating...");
        exit.send(AppExit::Success);
    }
}
