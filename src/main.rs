use bevy::input::keyboard::keyboard_input_system;
use bevy::prelude::*;
use log::debug;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_systems(Update, (keyboard_input_system, keyboard_log, detect_keys))
        .run();
}

fn setup(mut commands: Commands) {
    // Camera
    commands.spawn((Camera2d, IsDefaultUiCamera));
}

fn keyboard_log(keys: Res<ButtonInput<KeyCode>>) {
    debug!("keyboard: {:?}", keys.get_pressed().collect::<Vec<_>>());
}

fn detect_keys(keys: Res<ButtonInput<KeyCode>>, mut exit: EventWriter<AppExit>) {
    if keys.pressed(KeyCode::Escape) {
        debug!("GAME terminating...");
        exit.send(AppExit::Success);
    }
}

#[derive(Component, Debug, Clone)]
struct Ui;
