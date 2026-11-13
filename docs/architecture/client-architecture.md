# Client Architecture
Godot 4.4.1, typed GDScript and Compatibility renderer form the client baseline. Bootstrap is the entry point.

Autoloads: EventBus (notifications), GameState (application phase), SceneRouter (scene changes), ConfigService (settings), SaveService (versioned local save).

Scenes own presentation/lifecycle; Resources own reusable data. Keep autoloads small and avoid gameplay-specific global state. Profile touch UI, rendering and memory on representative devices. Signing material stays outside Git.
