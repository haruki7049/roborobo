use bevy::input::keyboard::keyboard_input_system;
use bevy::prelude::*;
use log::debug;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .insert_state(UiVisibleState::Visible)
        .add_systems(
            Update,
            (keyboard_input_system, keyboard_log, detect_keys, state_log),
        )
        .run();
}

fn setup(mut commands: Commands) {
    // Camera
    commands.spawn((Camera2d, IsDefaultUiCamera));
}

fn keyboard_log(keys: Res<ButtonInput<KeyCode>>) {
    debug!("keyboard: {:?}", keys.get_pressed().collect::<Vec<_>>());
}

fn detect_keys(
    keys: Res<ButtonInput<KeyCode>>,
    state: Res<State<UiVisibleState>>,
    mut next_state: ResMut<NextState<UiVisibleState>>,
    mut exit: EventWriter<AppExit>,
) {
    if keys.pressed(KeyCode::Escape) {
        debug!("GAME terminating...");
        exit.send(AppExit::Success);
    }
    if keys.just_pressed(KeyCode::Space) {
        debug!("Switching UI...");

        match state.get() {
            UiVisibleState::Visible => next_state.set(UiVisibleState::Invisible),
            UiVisibleState::Invisible => next_state.set(UiVisibleState::Visible),
        }
    }
}

fn state_log(state: Res<State<UiVisibleState>>) {
    debug!("UiVisibleState: {:?}", state.get());
}

#[derive(States, Hash, Debug, Clone, Eq, PartialEq)]
enum UiVisibleState {
    Visible,
    Invisible,
}
