use bevy::prelude::*;
use log::debug;

const NORMAL_BUTTON: Color = Color::srgb(0.15, 0.15, 0.15);
const HOVERED_BUTTON: Color = Color::srgb(0.25, 0.25, 0.25);
const PRESSED_BUTTON: Color = Color::srgb(0.25, 0.25, 0.25);

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        // For keyboard systems
        .add_systems(Update, bevy::input::keyboard::keyboard_input_system)
        .add_systems(Update, keyboard_log)
        .add_systems(Update, observe_quit_key_system)
        // For UI systems
        .add_systems(Update, switch_ui_system)
        .add_systems(Update, button_system)
        .run();
}

fn setup(mut commands: Commands) {
    // Camera
    commands.spawn((Camera2d, IsDefaultUiCamera));

    commands
        .spawn(Node {
            width: Val::Percent(100.0),
            height: Val::Percent(100.0),
            ..default()
        })
        .with_children(|parent| {
            parent.spawn((
                Button,
                Node {
                    width: Val::Percent(10.0),
                    height: Val::Percent(10.0),
                    border: UiRect::all(Val::Px(2.0)),
                    margin: UiRect::all(Val::Px(10.0)),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    ..default()
                },
                BorderColor(Color::BLACK),
                BorderRadius::MAX,
                BackgroundColor(NORMAL_BUTTON),
                Visibility::Visible,
            ));
        });
}

fn keyboard_log(keys: Res<ButtonInput<KeyCode>>) {
    debug!("keyboard: {:?}", keys.get_pressed().collect::<Vec<_>>());
}

fn observe_quit_key_system(keys: Res<ButtonInput<KeyCode>>, mut exit: EventWriter<AppExit>) {
    if keys.pressed(KeyCode::KeyQ)
        && (keys.pressed(KeyCode::ShiftLeft) || keys.pressed(KeyCode::ShiftRight))
    {
        debug!("GAME terminating...");
        exit.send(AppExit::Success);
    }
}

fn button_system(
    mut query: Query<
        (&Interaction, &mut BackgroundColor, &mut BorderColor),
        (Changed<Interaction>, With<Button>),
    >,
) {
    for (interaction, mut color, mut border_color) in &mut query {
        match *interaction {
            Interaction::Pressed => {
                *color = PRESSED_BUTTON.into();
                border_color.0 = bevy::color::palettes::basic::RED.into();
            }
            Interaction::Hovered => {
                *color = HOVERED_BUTTON.into();
                border_color.0 = Color::WHITE;
            }
            Interaction::None => {
                *color = NORMAL_BUTTON.into();
                border_color.0 = Color::BLACK;
            }
        }
    }
}

fn switch_ui_system(
    keys: Res<ButtonInput<KeyCode>>,
    mut query: Query<&mut Visibility, With<Button>>,
) {
    if keys.just_pressed(KeyCode::Space) {
        info!("Switching UI's visibility...");

        for mut ui in query.iter_mut() {
            ui.toggle_visible_hidden();
        }
    }
}
