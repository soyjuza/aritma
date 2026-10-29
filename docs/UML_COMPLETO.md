# UML completo (generado)

Generado por `tools/generar_uml.py` a partir del código: **175 clases**, un diagrama
por carpeta de `src/`. Las flechas `<|--` son herencia. Las relaciones entre paquetes
(composición, uso, eventos) están en el diagrama principal de `docs/ARQUITECTURA.md`.
Para actualizarlo: `python3 tools/generar_uml.py`.

## Raíz (Game)

```mermaid
classDiagram
    class Game {
        <<Node2D>>
        +load_level(new_level)
        +enter_chamber(index)
        +enter_temple()
        +next_practice(index) String
        +load_practice(key, index)
        +leave_practice()
        +skip_practice()
        +load_chamber(index)
        +show_title_shot()
        +follow_player()
        +place_title() String
        +key_names() Dictionary
        +text_speed() float
        +play_music(key)
        +fade_in()
        +fade_out()
        +talk(key)
        +talk_to(npc)
        +apply_skills()
        +grant_points(points)
        +notify(lines, seconds, good)
        +start_new_game()
        +open_codex(session)
        +save_game()
        +load_game()
        +load_map(id, entry)
        +go_to_map(id, entry)
        +chapter_done()
        +finish(won, ending)
        +combat(key, fallback)
        +fall_damage()
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `Game` | `Node2D` | `src/game.gd` |

## `src/core/` — Servicios del juego (datos, eventos, reloj, vidas, guardado)

```mermaid
classDiagram
    class AudioService {
        <<Facade>>
        +play_sfx(sound)
        +play_music(track)
        +set_volume(bus_name, level)
    }
    class DataRepository {
        <<RefCounted>>
        +use_touch()
        +setting(key, fallback)
        +use_chapter(i)
        +use_order(ids)
        +room_id(room) String$
        +chapter_data(i) Dictionary
        +map_data(id) Dictionary
        +map_of_chapter(i) String
        +chapter_name(i) String
        +chamber_count() int
        +chamber_data(index) Dictionary
        +practice(key) Dictionary
        +talk(key) Array
        +message(key, params) String
        +messages(key) Array
    }
    class EventBus {
        <<Observer>>
        +subscribe(event, callback)
        +unsubscribe(event, callback)
        +publish(event, payload)
    }
    class GameEvents {
        <<RefCounted>>
    }
    class InputSetup {
        <<RefCounted>>
        +register(controls)$
        +key_name(action) String$
        +drop_mouse_bindings()$
    }
    class LifeRules {
        <<RefCounted>>
        +fall_damage()
    }
    class PlayerHealth {
        <<RefCounted>>
        +hearts() int
        +is_dead() bool
        +damage(amount) bool
        +heal(amount)
        +refill()
    }
    class QuestLog {
        <<RefCounted>>
        +quest(id) Dictionary
        +state(id) String
        +reset()
        +found_count(id) int
        +done_count() int
        +talk(id)
        +pick(item, id)
        +save_state() Dictionary
        +restore(data)
    }
    class SaveRepository {
        <<RefCounted>>
        +exists() bool
        +save(snapshot)
        +load_snapshot() Dictionary
        +clear()
    }
    class SecretCodeDetector {
        <<RefCounted>>
        +feed(unicode) bool
    }
    class SettingsRepository {
        <<RefCounted>>
        +get_int(key) int
        +get_bool(key) bool
        +set_value(key, value)
        +save()
        +apply()
    }
    class SkillTree {
        <<RefCounted>>
        +skill(id) Dictionary
        +level(id) int
        +max_level(id) int
        +free_points() int
        +can_raise(id) bool
        +raise(id) bool
        +grant(points)
        +reset()
        +save_state() Dictionary
        +restore(data)
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `AudioService` | `RefCounted` | `src/core/audio_service.gd` |
| `DataRepository` | `RefCounted` | `src/core/data_repository.gd` |
| `EventBus` | `RefCounted` | `src/core/event_bus.gd` |
| `GameEvents` | `RefCounted` | `src/core/game_events.gd` |
| `InputSetup` | `RefCounted` | `src/core/input_setup.gd` |
| `LifeRules` | `RefCounted` | `src/core/life_rules.gd` |
| `PlayerHealth` | `RefCounted` | `src/core/player_health.gd` |
| `QuestLog` | `RefCounted` | `src/core/quest_log.gd` |
| `SaveRepository` | `RefCounted` | `src/core/save_repository.gd` |
| `SecretCodeDetector` | `RefCounted` | `src/core/secret_code_detector.gd` |
| `SettingsRepository` | `RefCounted` | `src/core/settings_repository.gd` |
| `SkillTree` | `RefCounted` | `src/core/skill_tree.gd` |

## `src/player/` — Tala y sus estados (patrón State)

```mermaid
classDiagram
    class PlayerController {
        <<CharacterBody2D>>
        +setup(bus, movement)
        +change(next)
        +input_vector() Vector2
        +has_move_input() bool
        +wants_run() bool
        +wants_jump() bool
        +wants_attack() bool
        +move_toward_input(speed, delta)
        +spend_stamina(delta)
        +jumped()
        +landed()
        +fall()
        +apply_combat(values)
        +start_swing()
        +update_swing(k)
        +end_swing()
        +strike()
        +hurt(amount, from, force)
        +die()
        +set_lamp(on)
        +place(at, face)
        +focused_interactable() Interactable
    }
    class AttackState {
        <<State>>
        +enter(_previous)
        +exit()
        +physics(delta) String
        +animation() String
        +stops_on_death() bool
    }
    class FallState {
        <<State>>
        +physics(_delta) String
        +animation() String
    }
    class GroundState {
        <<State>>
        +speed() float
        +physics(delta) String
        +transition() String
    }
    class IdleState {
        <<State>>
        +transition() String
    }
    class JumpState {
        <<State>>
        +enter(_previous)
        +exit()
        +physics(delta) String
        +animation() String
    }
    class MoveState {
        <<State>>
        +enter(_previous)
        +exit()
        +physics(_delta) String
        +animation() String
        +animation_speed() float
        +regenerates_stamina() bool
        +stops_on_death() bool
    }
    class RunState {
        <<State>>
        +speed() float
        +physics(delta) String
        +transition() String
        +animation() String
        +animation_speed() float
        +regenerates_stamina() bool
    }
    class WalkState {
        <<State>>
        +speed() float
        +transition() String
        +animation() String
    }
    MoveState <|-- AttackState
    MoveState <|-- FallState
    MoveState <|-- GroundState
    GroundState <|-- IdleState
    MoveState <|-- JumpState
    GroundState <|-- RunState
    GroundState <|-- WalkState
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `PlayerController` | `CharacterBody2D` | `src/player/player_controller.gd` |
| `AttackState` | `MoveState` | `src/player/states/attack_state.gd` |
| `FallState` | `MoveState` | `src/player/states/fall_state.gd` |
| `GroundState` | `MoveState` | `src/player/states/ground_state.gd` |
| `IdleState` | `GroundState` | `src/player/states/idle_state.gd` |
| `JumpState` | `MoveState` | `src/player/states/jump_state.gd` |
| `MoveState` | `RefCounted` | `src/player/states/move_state.gd` |
| `RunState` | `GroundState` | `src/player/states/run_state.gd` |
| `WalkState` | `GroundState` | `src/player/states/walk_state.gd` |

## `src/enemies/` — Guardianes, jefe, sus estados (State) y ataques (Strategy)

```mermaid
classDiagram
    class GuardianAttack {
        <<Strategy>>
        +windup_time() float
        +cooldown() float
        +perform(_guardian, _player)
    }
    class MeleeStrike {
        <<Strategy>>
        +perform(guardian, player)
    }
    class OrbShot {
        <<Strategy>>
        +windup_time() float
        +cooldown() float
        +perform(guardian, player)
    }
    class RuneBlast {
        <<Strategy>>
        +windup_time() float
        +cooldown() float
        +perform(guardian, player)
    }
    class BossAppearState {
        <<State>>
        +enter()
        +physics(delta) String
        +animation() String
        +hittable() bool
    }
    class BossChaseState {
        <<State>>
        +physics(delta) String
        +animation() String
    }
    class BossDyingState {
        <<State>>
        +enter()
        +physics(delta) String
        +animation() String
        +hittable() bool
    }
    class BossHiddenState {
        <<State>>
        +enter()
        +hittable() bool
    }
    class BossShieldState {
        <<State>>
        +enter()
        +physics(delta) String
        +hittable() bool
    }
    class BossSlamState {
        <<State>>
        +enter()
        +physics(delta) String
        +draw()
    }
    class BossState {
        <<State>>
        +enter()
        +exit()
        +physics(_delta) String
        +animation() String
        +hittable() bool
        +draw()
    }
    class BossTiredState {
        <<State>>
        +physics(delta) String
        +animation() String
        +draw()
    }
    class BossVolleyState {
        <<State>>
        +enter()
        +physics(delta) String
        +animation() String
    }
    class BossWaitState {
        <<State>>
        +physics(delta) String
    }
    class Guardian {
        <<CharacterBody2D>>
        +is_ranged() bool
        +setup(p_bus, p_kit, p_settings)
        +change(next)
        +dir_name() String
        +wake()
        +drop(at)
        +restore()
        +dissolve()
        +is_active() bool
        +can_be_hit() bool
        +take_hit(amount, direction)
        +blow_up()
        +on_windup()
        +on_landed()
        +formation_target() Vector2
        +formation_slot() float
        +in_formation() bool
        +clear_shot(from) bool
        +blink() bool
        +player() PlayerController
        +to_player() Vector2
        +pace() float
        +setting(key, fallback)
        +burst(at, fx, amount, lifetime, gravity, 60)
        +separation() Vector2
    }
    class RuneOrb {
        <<Node2D>>
        +shatter()
    }
    class RunicGuardian {
        +on_windup()
        +on_landed()
        +explosion_fx()
    }
    class ChaseState {
        <<State>>
        +enter()
        +physics(delta) String
        +animation() String
        +hittable() bool
    }
    class DormantState {
        <<State>>
        +enter()
        +physics(delta) String
    }
    class DroppingState {
        <<State>>
        +enter()
        +exit()
        +physics(delta) String
        +animation() String
    }
    class DyingState {
        <<State>>
        +enter()
    }
    class GuardianState {
        <<State>>
        +enter()
        +exit()
        +physics(_delta) String
        +animation() String
        +hittable() bool
    }
    class StaggerState {
        <<State>>
        +enter()
        +exit()
        +physics(delta) String
        +animation() String
        +hittable() bool
    }
    class StrikeState {
        <<State>>
        +enter()
        +physics(delta) String
        +animation() String
        +hittable() bool
    }
    class WakingState {
        <<State>>
        +enter()
        +exit()
        +physics(delta) String
        +animation() String
    }
    class WindupState {
        <<State>>
        +enter()
        +exit()
        +physics(delta) String
        +hittable() bool
    }
    class ZeroBoss {
        <<CharacterBody2D>>
        +setup(p_bus, p_alarm, tuning)
        +change(next)
        +appear()
        +reset_for_retry()
        +answered(right)
        +is_awake() bool
        +phase_hp() int
        +can_be_hit() bool
        +take_hit(amount, direction)
        +publish(event)
        +player() PlayerController
        +return_home()
        +brake(delta)
        +anim_length(anim) float
    }
    GuardianAttack <|-- MeleeStrike
    GuardianAttack <|-- OrbShot
    GuardianAttack <|-- RuneBlast
    BossState <|-- BossAppearState
    BossState <|-- BossChaseState
    BossState <|-- BossDyingState
    BossState <|-- BossHiddenState
    BossState <|-- BossShieldState
    BossState <|-- BossSlamState
    BossState <|-- BossTiredState
    BossState <|-- BossVolleyState
    BossState <|-- BossWaitState
    Guardian <|-- RunicGuardian
    GuardianState <|-- ChaseState
    GuardianState <|-- DormantState
    GuardianState <|-- DroppingState
    GuardianState <|-- DyingState
    GuardianState <|-- StaggerState
    GuardianState <|-- StrikeState
    GuardianState <|-- WakingState
    GuardianState <|-- WindupState
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `GuardianAttack` | `RefCounted` | `src/enemies/attacks/guardian_attack.gd` |
| `MeleeStrike` | `GuardianAttack` | `src/enemies/attacks/melee_strike.gd` |
| `OrbShot` | `GuardianAttack` | `src/enemies/attacks/orb_shot.gd` |
| `RuneBlast` | `GuardianAttack` | `src/enemies/attacks/rune_blast.gd` |
| `BossAppearState` | `BossState` | `src/enemies/boss_states/boss_appear_state.gd` |
| `BossChaseState` | `BossState` | `src/enemies/boss_states/boss_chase_state.gd` |
| `BossDyingState` | `BossState` | `src/enemies/boss_states/boss_dying_state.gd` |
| `BossHiddenState` | `BossState` | `src/enemies/boss_states/boss_hidden_state.gd` |
| `BossShieldState` | `BossState` | `src/enemies/boss_states/boss_shield_state.gd` |
| `BossSlamState` | `BossState` | `src/enemies/boss_states/boss_slam_state.gd` |
| `BossState` | `RefCounted` | `src/enemies/boss_states/boss_state.gd` |
| `BossTiredState` | `BossState` | `src/enemies/boss_states/boss_tired_state.gd` |
| `BossVolleyState` | `BossState` | `src/enemies/boss_states/boss_volley_state.gd` |
| `BossWaitState` | `BossState` | `src/enemies/boss_states/boss_wait_state.gd` |
| `Guardian` | `CharacterBody2D` | `src/enemies/guardian.gd` |
| `RuneOrb` | `Node2D` | `src/enemies/rune_orb.gd` |
| `RunicGuardian` | `Guardian` | `src/enemies/runic_guardian.gd` |
| `ChaseState` | `GuardianState` | `src/enemies/states/chase_state.gd` |
| `DormantState` | `GuardianState` | `src/enemies/states/dormant_state.gd` |
| `DroppingState` | `GuardianState` | `src/enemies/states/dropping_state.gd` |
| `DyingState` | `GuardianState` | `src/enemies/states/dying_state.gd` |
| `GuardianState` | `RefCounted` | `src/enemies/states/guardian_state.gd` |
| `StaggerState` | `GuardianState` | `src/enemies/states/stagger_state.gd` |
| `StrikeState` | `GuardianState` | `src/enemies/states/strike_state.gd` |
| `WakingState` | `GuardianState` | `src/enemies/states/waking_state.gd` |
| `WindupState` | `GuardianState` | `src/enemies/states/windup_state.gd` |
| `ZeroBoss` | `CharacterBody2D` | `src/enemies/zero_boss.gd` |

## `src/chambers/` — Salas, máquinas, fábricas (Factory Method), órdenes (Command) y problemas del jefe (Strategy)

```mermaid
classDiagram
    class AlarmDirector {
        <<Observer>>
        +setup(game, room)
        +enabled() bool
        +fighting() bool
        +alive_count() int
        +alive_by_kind() Dictionary
        +wave_size(n) int
        +runic_count(n) int
        +ranged_count(n) int
        +wave_kinds(n) Array
        +challenge(n) Dictionary
        +wave_speed(n) float
        +summon(n)
        +calm()
        +reset_after_death()
    }
    class BeaconMachine {
        +setup(bus, data, text, open_codex)
        +status_text() String
        +make_tables(_i) Array
        +react(right)
    }
    class BellsMachine {
        +setup(bus, data, text, open_codex)
        +make_tables(_i) Array
        +show_round(i)
        +react(_right)
    }
    class BossQuiz {
        <<RefCounted>>
        +kinds() Array
        +make(kind, rng) Dictionary
    }
    class BridgeMachine {
        +setup(bus, data, text, open_codex)
        +make_tables(i) Array
    }
    class ChamberBuilder {
        <<Factory Method>>
        +build(data) ChamberLevel
        +create_level() ChamberLevel
    }
    class ChamberLevel {
        +open_exit()
        +machine_blocked() bool
        +lock_machines(on)
        +room_entrance() Vector2
        +save_state() Dictionary
        +resume_from_save(state)
        +restore_solved()
        +restart_after_death()
    }
    class ChamberRegistry {
        <<RefCounted>>
        +register(kind, builder)$
        +create(data) ChamberLevel$
    }
    class CodeMachine {
        <<Template Method>>
        +evaluate(_source, _engine) Report
        +perform(_report)
        +status_text() String
        +view_center() Vector2
        +mark_solved()
        +show_code(source)
        +set_locked(on)
        +connect_console(open_codex)
    }
    class CoreBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class CoreLevel {
        +wire()
        +rule_lines(key) Array
        +hud_line() String
        +player_fall()
    }
    class CribaMachine {
        <<Command>>
        +setup(bus, data, text, open_codex)
        +make_tables(i) Array
        +new_rounds(keep_first)
        +evaluate(source, engine) CodeMachine
        +status_text() String
        +perform(report)
        +load_round(index, rows)
        +drop_to_gate()
        +send_from_gate(to_chalice, right)
        +jam()
        +round_done(index)
    }
    class CribaSphere {
        <<Node2D>>
    }
    class CribaView {
        <<RefCounted>>
        +draw_board(ci, gate_open, round_lit, filled, time)$
    }
    class ExitZone {
    }
    class FigureBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class FigureLevel {
        +wire()
        +restore_solved()
    }
    class FigurePuzzle {
        <<RefCounted>>
        +from_layout(layout, p_title, turned, rng) FigurePuzzle$
        +corner(cells) Vector2i$
        +normalized(cells) Array~Vector2i~$
        +extent(cells) Vector2i$
        +cells_of(i) Array~Vector2i~
        +rotate(i)
        +is_placed(i) bool
        +occupied(except) Dictionary
        +can_place(i, at) bool
        +place(i, at) bool
        +lift(i)
        +is_solved() bool
    }
    class FigureTable {
        <<Node2D>>
        +setup(data, rng, open_puzzle)
        +puzzle() FigurePuzzle
        +advance() bool
    }
    class FilterBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class FilterCommand {
        <<Command>>
        +run(_machine)
    }
    class FilterLevel {
        +wire()
    }
    class GardenMachine {
        +make_tables(_i) Array
    }
    class GateMachine {
        +on_open(open_fn)
        +setup(bus, data, text, open_codex)
        +status_text() String
        +make_tables(_i) Array
        +react(right)
        +mark_solved()
    }
    class LockBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class LockLevel {
        +wire()
    }
    class LockMachine {
        +setup(bus, data, text, open_codex)
        +status_text() String
        +make_tables(i) Array
        +show_round(i)
        +react(_right)
        +mark_solved()
    }
    class MillMachine {
        +make_tables(_i) Array
        +show_round(i)
        +react(_right)
    }
    class MineBoard {
        <<Node2D>>
        +cells() Array~Vector2i~
        +in_board(c) bool
        +cell_at(world) Vector2i
        +cell_center(c) Vector2
        +power_on()
        +reveal(c) Result
        +toggle_flag(c) bool
        +is_cleared() bool
        +reset()
        +show_solved()
        +neighbors(c) Array~Vector2i~
        +count_around(c) int
    }
    class MinefieldGenerator {
        <<RefCounted>>
        +generate(cells, mine_count, first) Dictionary
        +is_solvable(field, mines, first) bool
        +neighbors(field, cell) Array~Vector2i~
        +count_mines(field, mines, cell) int
    }
    class MuralMachine {
        +setup(bus, data, text, open_codex)
        +status_text() String
        +make_tables(_i) Array
        +show_round(i)
        +react(_right)
        +mark_solved()
    }
    class NumberPath {
        <<Node2D>>
        +generate(rng, p_multiple, extra_safe, top)
        +in_grid(c) bool
        +is_safe(c) bool
        +origin() Vector2
        +cell_rect(c) Rect2
        +cell_center_global(c) Vector2
        +cell_at(world) Vector2i
        +over_void(world) bool
        +crumble(c)
    }
    class PumpMachine {
        +setup(bus, data, text, open_codex)
        +make_tables(_i) Array
        +show_round(i)
        +react(_right)
    }
    class JoinProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class KeywordProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class OrderProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class QuizProblem {
        <<Strategy>>
        +make(_rng) Dictionary
        +say(key, params) String
        +pick(right, wrong, count) Dictionary$
    }
    class SelectProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class SortProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class SqlProblem {
        <<Strategy>>
        +make_table(rng) SqlTable
        +run_text(query, tables) String
        +run_count(query, tables) int
        +choices(right, wrong, extra, rng) Dictionary
        +name_lists(t, rng) Array
        +problem(title_key, question_key, tables, code, pick, params) Dictionary
        +shuffled(list, rng) Array$
    }
    class WhereProblem {
        <<Strategy>>
        +make(rng) Dictionary
    }
    class RootsBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class RootsLevel {
        +wire()
    }
    class RoundsLevel {
        +wire()
    }
    class ScaleMachine {
        +make_tables(_i) Array
        +show_round(i)
        +react(_right)
    }
    class SceneBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class SphereSorter {
        <<RefCounted>>
        +add_round(index, rows, chosen, wanted, columns_ok) bool
    }
    class SqlMachine {
        <<Template Method>>
        +setup(bus, data, text, open_codex)
        +status_text() String
        +make_tables(_i) Array
        +new_rounds(keep_first)
        +show_round(i)
        +table(name) SqlTable
        +got_values(name) Array
        +evaluate(source, engine) CodeMachine
        +perform(report)
        +react(_right)
        +mark_solved()
    }
    class TableSign {
        <<RefCounted>>
        +measure(font, columns, rows, size, title) Vector2$
        +draw(ci, font, columns, rows, at, size, title, marks) Rect2$
        +text(ci, font, s, at, size, color, centered)$
    }
    class ThroneBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class ThroneLevel {
        +wire()
        +restart_after_death()
    }
    class TwinsMachine {
        +make_tables(_i) Array
    }
    class VortexBuilder {
        <<Factory Method>>
        +create_level() ChamberLevel
    }
    class VortexLevel {
        +wire()
        +handle_action(actions) bool
        +action_prompt() Dictionary
        +hud_line() String
        +restore_solved()
        +restart_after_death()
        +touch_actions() Array
    }
    SqlMachine <|-- BeaconMachine
    SqlMachine <|-- BellsMachine
    SqlMachine <|-- BridgeMachine
    Level <|-- ChamberLevel
    ChamberBuilder <|-- CoreBuilder
    ChamberLevel <|-- CoreLevel
    SqlMachine <|-- CribaMachine
    TriggerZone <|-- ExitZone
    ChamberBuilder <|-- FigureBuilder
    ChamberLevel <|-- FigureLevel
    ChamberBuilder <|-- FilterBuilder
    ChamberLevel <|-- FilterLevel
    SqlMachine <|-- GardenMachine
    SqlMachine <|-- GateMachine
    ChamberBuilder <|-- LockBuilder
    ChamberLevel <|-- LockLevel
    SqlMachine <|-- LockMachine
    SqlMachine <|-- MillMachine
    SqlMachine <|-- MuralMachine
    SqlMachine <|-- PumpMachine
    SqlProblem <|-- JoinProblem
    SqlProblem <|-- KeywordProblem
    QuizProblem <|-- OrderProblem
    SqlProblem <|-- SelectProblem
    SqlProblem <|-- SortProblem
    QuizProblem <|-- SqlProblem
    SqlProblem <|-- WhereProblem
    ChamberBuilder <|-- RootsBuilder
    ChamberLevel <|-- RootsLevel
    ChamberLevel <|-- RoundsLevel
    SqlMachine <|-- ScaleMachine
    ChamberBuilder <|-- SceneBuilder
    CodeMachine <|-- SqlMachine
    ChamberBuilder <|-- ThroneBuilder
    ChamberLevel <|-- ThroneLevel
    SqlMachine <|-- TwinsMachine
    ChamberBuilder <|-- VortexBuilder
    ChamberLevel <|-- VortexLevel
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `AlarmDirector` | `Node` | `src/chambers/alarm_director.gd` |
| `BeaconMachine` | `SqlMachine` | `src/chambers/beacon_machine.gd` |
| `BellsMachine` | `SqlMachine` | `src/chambers/bells_machine.gd` |
| `BossQuiz` | `RefCounted` | `src/chambers/boss_quiz.gd` |
| `BridgeMachine` | `SqlMachine` | `src/chambers/bridge_machine.gd` |
| `ChamberBuilder` | `RefCounted` | `src/chambers/chamber_builder.gd` |
| `ChamberLevel` | `Level` | `src/chambers/chamber_level.gd` |
| `ChamberRegistry` | `RefCounted` | `src/chambers/chamber_registry.gd` |
| `CodeMachine` | `Node2D` | `src/chambers/code_machine.gd` |
| `CoreBuilder` | `ChamberBuilder` | `src/chambers/core_builder.gd` |
| `CoreLevel` | `ChamberLevel` | `src/chambers/core_level.gd` |
| `CribaMachine` | `SqlMachine` | `src/chambers/criba_machine.gd` |
| `CribaSphere` | `Node2D` | `src/chambers/criba_sphere.gd` |
| `CribaView` | `RefCounted` | `src/chambers/criba_view.gd` |
| `ExitZone` | `TriggerZone` | `src/chambers/exit_zone.gd` |
| `FigureBuilder` | `ChamberBuilder` | `src/chambers/figure_builder.gd` |
| `FigureLevel` | `ChamberLevel` | `src/chambers/figure_level.gd` |
| `FigurePuzzle` | `RefCounted` | `src/chambers/figure_puzzle.gd` |
| `FigureTable` | `Node2D` | `src/chambers/figure_table.gd` |
| `FilterBuilder` | `ChamberBuilder` | `src/chambers/filter_builder.gd` |
| `FilterCommand` | `RefCounted` | `src/chambers/filter_command.gd` |
| `FilterLevel` | `ChamberLevel` | `src/chambers/filter_level.gd` |
| `GardenMachine` | `SqlMachine` | `src/chambers/garden_machine.gd` |
| `GateMachine` | `SqlMachine` | `src/chambers/gate_machine.gd` |
| `LockBuilder` | `ChamberBuilder` | `src/chambers/lock_builder.gd` |
| `LockLevel` | `ChamberLevel` | `src/chambers/lock_level.gd` |
| `LockMachine` | `SqlMachine` | `src/chambers/lock_machine.gd` |
| `MillMachine` | `SqlMachine` | `src/chambers/mill_machine.gd` |
| `MineBoard` | `Node2D` | `src/chambers/mine_board.gd` |
| `MinefieldGenerator` | `RefCounted` | `src/chambers/minefield_generator.gd` |
| `MuralMachine` | `SqlMachine` | `src/chambers/mural_machine.gd` |
| `NumberPath` | `Node2D` | `src/chambers/number_path.gd` |
| `PumpMachine` | `SqlMachine` | `src/chambers/pump_machine.gd` |
| `JoinProblem` | `SqlProblem` | `src/chambers/quiz/join_problem.gd` |
| `KeywordProblem` | `SqlProblem` | `src/chambers/quiz/keyword_problem.gd` |
| `OrderProblem` | `QuizProblem` | `src/chambers/quiz/order_problem.gd` |
| `QuizProblem` | `RefCounted` | `src/chambers/quiz/quiz_problem.gd` |
| `SelectProblem` | `SqlProblem` | `src/chambers/quiz/select_problem.gd` |
| `SortProblem` | `SqlProblem` | `src/chambers/quiz/sort_problem.gd` |
| `SqlProblem` | `QuizProblem` | `src/chambers/quiz/sql_problem.gd` |
| `WhereProblem` | `SqlProblem` | `src/chambers/quiz/where_problem.gd` |
| `RootsBuilder` | `ChamberBuilder` | `src/chambers/roots_builder.gd` |
| `RootsLevel` | `ChamberLevel` | `src/chambers/roots_level.gd` |
| `RoundsLevel` | `ChamberLevel` | `src/chambers/rounds_level.gd` |
| `ScaleMachine` | `SqlMachine` | `src/chambers/scale_machine.gd` |
| `SceneBuilder` | `ChamberBuilder` | `src/chambers/scene_builder.gd` |
| `SphereSorter` | `RefCounted` | `src/chambers/sphere_sorter.gd` |
| `SqlMachine` | `CodeMachine` | `src/chambers/sql_machine.gd` |
| `TableSign` | `RefCounted` | `src/chambers/table_sign.gd` |
| `ThroneBuilder` | `ChamberBuilder` | `src/chambers/throne_builder.gd` |
| `ThroneLevel` | `ChamberLevel` | `src/chambers/throne_level.gd` |
| `TwinsMachine` | `SqlMachine` | `src/chambers/twins_machine.gd` |
| `VortexBuilder` | `ChamberBuilder` | `src/chambers/vortex_builder.gd` |
| `VortexLevel` | `ChamberLevel` | `src/chambers/vortex_level.gd` |

## `src/sql_lang/` — El SQL del Códice: lexer, parser, motor y comparador (Interpreter, Facade)

```mermaid
classDiagram
    class SqlCheck {
        <<RefCounted>>
        +compare(got, want, ordered) Dictionary$
    }
    class SqlEngine {
        <<Facade>>
        +run(source, tables) Result
        +is_number(v) bool$
        +show(v) String$
        +count_lines(source) int$
        +grid(columns, rows, max_rows) Array$
        +result_lines(result) Array$
    }
    class SqlLexer {
        <<Interpreter>>
        +tokenize(source) Array
    }
    class SqlMessages {
        <<RefCounted>>
        +text(key, params) String$
    }
    class SqlParser {
        <<Interpreter>>
        +parse(tokens) SqlQuery
        +distance(a, b) int$
    }
    class SqlQuery {
        <<Interpreter>>
    }
    class SqlTable {
        <<RefCounted>>
        +from_data(data) SqlTable$
        +to_data() Dictionary
        +column_index(column) int
        +rows_with(column, values) Array
        +lines(max_rows) Array
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `SqlCheck` | `RefCounted` | `src/sql_lang/sql_check.gd` |
| `SqlEngine` | `RefCounted` | `src/sql_lang/sql_engine.gd` |
| `SqlLexer` | `RefCounted` | `src/sql_lang/sql_lexer.gd` |
| `SqlMessages` | `RefCounted` | `src/sql_lang/sql_messages.gd` |
| `SqlParser` | `RefCounted` | `src/sql_lang/sql_parser.gd` |
| `SqlQuery` | `RefCounted` | `src/sql_lang/sql_query.gd` |
| `SqlTable` | `RefCounted` | `src/sql_lang/sql_table.gd` |

## `src/states/` — Pantallas del juego (patrón State)

```mermaid
classDiagram
    class BookState {
        <<State>>
        +enter(params)
        +freezes_world() bool
        +touch_buttons() Array
        +handle_input(actions)
        +draw(ui)
    }
    class CodexState {
        <<State>>
        +enter(params)
        +exit()
        +touch_buttons() Array
        +handle_input(actions)
        +run()
        +draw(ui)
    }
    class CreditsState {
        <<State>>
        +touch_tap() String
        +handle_input(actions)
        +draw(ui)
    }
    class EndState {
        <<State>>
        +enter(params)
        +touch_tap() String
        +handle_input(actions)
        +update(delta)
        +draw(ui)
    }
    class GameState {
        <<State>>
        +enter(_params)
        +exit()
        +handle_input(_actions)
        +handle_key(_event) bool
        +handle_mouse(_event) bool
        +update(_delta)
        +draw(_ui)
        +freezes_world() bool
        +touch_buttons() Array
        +touch_tap() String
        +touch_stick() bool
        +touch_keys() Array
    }
    class IntroState {
        <<State>>
        +enter(_params)
        +touch_tap() String
        +touch_buttons() Array
        +handle_input(actions)
        +update(delta)
        +draw(ui)
    }
    class KeyChallengeState {
        <<State>>
        +random_keys(pool, count) Array$
        +enter(params)
        +exit()
        +touch_keys() Array
        +handle_key(event) bool
        +is_getting_ready() bool
        +time_left() float
        +update(_delta)
        +draw(ui)
    }
    class MenuState {
        <<State>>
        +enter(_params)
        +handle_mouse(event) bool
        +handle_input(actions)
        +draw(ui)
    }
    class PauseState {
        <<State>>
        +enter(params)
        +freezes_world() bool
        +handle_mouse(event) bool
        +handle_input(actions)
        +update(delta)
        +draw(ui)
    }
    class PlayState {
        <<State>>
        +enter(params)
        +exit()
        +touch_stick() bool
        +touch_tap() String
        +touch_buttons() Array
        +handle_input(actions)
        +update(delta)
        +draw(ui)
    }
    class PuzzleState {
        <<State>>
        +enter(params)
        +exit()
        +freezes_world() bool
        +handle_mouse(event) bool
        +touch_buttons() Array
        +handle_input(actions)
        +check_solved(ui)
        +update(_delta)
        +draw(ui)
    }
    class QuizState {
        <<State>>
        +enter(params)
        +freezes_world() bool
        +handle_key(event) bool
        +handle_mouse(event) bool
        +choose(i)
        +right() bool
        +update(delta)
        +draw(ui)
    }
    class SettingsState {
        <<State>>
        +enter(params)
        +freezes_world() bool
        +touch_buttons() Array
        +handle_mouse(event) bool
        +handle_input(actions)
        +draw(ui)
    }
    class SkillsState {
        <<State>>
        +enter(_params)
        +freezes_world() bool
        +touch_buttons() Array
        +handle_mouse(event) bool
        +handle_input(actions)
        +draw(ui)
    }
    class StateMachine {
        <<State>>
        +add(state_name, state)
        +get_state(state_name) GameState
        +change(state_name, params)
    }
    class TitleState {
        <<State>>
        +enter(_params)
        +touch_tap() String
        +handle_input(actions)
        +draw(ui)
    }
    GameState <|-- BookState
    GameState <|-- CodexState
    GameState <|-- CreditsState
    GameState <|-- EndState
    GameState <|-- IntroState
    GameState <|-- KeyChallengeState
    GameState <|-- MenuState
    GameState <|-- PauseState
    GameState <|-- PlayState
    GameState <|-- PuzzleState
    GameState <|-- QuizState
    GameState <|-- SettingsState
    GameState <|-- SkillsState
    GameState <|-- TitleState
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `BookState` | `GameState` | `src/states/book_state.gd` |
| `CodexState` | `GameState` | `src/states/codex_state.gd` |
| `CreditsState` | `GameState` | `src/states/credits_state.gd` |
| `EndState` | `GameState` | `src/states/end_state.gd` |
| `GameState` | `RefCounted` | `src/states/game_state.gd` |
| `IntroState` | `GameState` | `src/states/intro_state.gd` |
| `KeyChallengeState` | `GameState` | `src/states/key_challenge_state.gd` |
| `MenuState` | `GameState` | `src/states/menu_state.gd` |
| `PauseState` | `GameState` | `src/states/pause_state.gd` |
| `PlayState` | `GameState` | `src/states/play_state.gd` |
| `PuzzleState` | `GameState` | `src/states/puzzle_state.gd` |
| `QuizState` | `GameState` | `src/states/quiz_state.gd` |
| `SettingsState` | `GameState` | `src/states/settings_state.gd` |
| `SkillsState` | `GameState` | `src/states/skills_state.gd` |
| `StateMachine` | `RefCounted` | `src/states/state_machine.gd` |
| `TitleState` | `GameState` | `src/states/title_state.gd` |

## `src/ui/` — Interfaz

```mermaid
classDiagram
    class BlockBoard {
        <<Control>>
        +font_size() int
        +program_rect() Rect2
        +tray_rect() Rect2
        +row_height() float
        +piece_size(piece) Vector2
        +row_rect(row) Rect2
        +tray_layout() Dictionary
        +row_at(point) int
        +tray_piece_at(point) int
        +drop_target() Vector2i
        +max_indent(row) int
        +place(piece, row, indent)
        +take_back(row)
        +shift(row, delta)
        +move(row, delta)
        +suggested_indent(row) int
    }
    class CodexPanel {
        <<Control>>
        +fold(folded)
        +open(session, keys_text, side)
        +close() String
        +source() String
        +write(code)
        +toggle_mode()
        +show_mode()
        +log_line(text, color)
    }
    class CodexSession {
        <<RefCounted>>
        +count_lines(source) int$
        +set_blocks(lines)
        +free_pieces() Array
        +blocks_source() String
        +blocks_state() Dictionary
        +restore_blocks(state)
    }
    class DialogBox {
        <<RefCounted>>
        +is_open() bool
        +say(texts, on_done)
        +close()
        +update(delta, chars_per_second)
        +advance()
        +draw(ui)
    }
    class Hud {
        <<RefCounted>>
        +draw(ui, info)
        +draw_notice(ui, text, left, good, top, place)
        +draw_hearts(ui, health, hurt)
        +draw_alarm(ui, level, guardians, label)
    }
    class MenuList {
        <<RefCounted>>
        +move(actions) bool
        +is_enabled(i) bool
        +first_enabled()
        +selected() String
        +height() float
        +index_at(point) int
        +clicked(event, point) bool
        +draw(ui, at, width)
    }
    class NoticeBoard {
        <<RefCounted>>
        +notify(lines, seconds, is_good, is_place)
        +tick(delta)
    }
    class OverlayCanvas {
        <<Control>>
    }
    class ScreenFade {
        <<RefCounted>>
        +fade_in()
        +fade_out()
        +tick(delta)
    }
    class TouchControls {
        <<Control>>
        +setup(p_game, p_names, mouse_as_finger)
    }
    class UIKit {
        <<RefCounted>>
        +size() Vector2
        +font(name) Font
        +rect(r, color)
        +frame(r, color, width)
        +line(a, b, color, width)
        +diamond(center, half, color)
        +arc(center, radius, from, to, color, width)
        +panel(r, fill)
        +pill(r, fill, border)
        +text(s, at, font_size, color, font_name, shadow)
        +text_centered(s, y, font_size, color, font_name, center_x)
        +text_right(s, right_x, y, font_size, color, font_name)
        +measure(s, font_size, font_name) float
        +line_height(font_size, font_name) float
        +wrap(s, max_width, font_size, font_name) Array
        +key_hint(key, label_text, at, font_size) float
        +cursor(at, color)
        +more_arrow(at)
        +blink(rate) bool
        +dim(amount)
        +bar(at, level, maximum, color)
        +texture_region(texture, dest, source, modulate)
        +vignette(strength, color)
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `BlockBoard` | `Control` | `src/ui/block_board.gd` |
| `CodexPanel` | `Control` | `src/ui/codex_panel.gd` |
| `CodexSession` | `RefCounted` | `src/ui/codex_session.gd` |
| `DialogBox` | `RefCounted` | `src/ui/dialog_box.gd` |
| `Hud` | `RefCounted` | `src/ui/hud.gd` |
| `MenuList` | `RefCounted` | `src/ui/menu_list.gd` |
| `NoticeBoard` | `RefCounted` | `src/ui/notice_board.gd` |
| `OverlayCanvas` | `Control` | `src/ui/overlay_canvas.gd` |
| `ScreenFade` | `RefCounted` | `src/ui/screen_fade.gd` |
| `TouchControls` | `Control` | `src/ui/touch_controls.gd` |
| `UIKit` | `RefCounted` | `src/ui/ui_kit.gd` |

## `src/world/` — Piezas de los mapas

```mermaid
classDiagram
    class Barrier {
        <<Node2D>>
        +set_open(on)
        +crumble()
    }
    class CheckpointZone {
        +point() Vector2
    }
    class Crusher {
        <<Node2D>>
        +extension() float
        +warning() bool
    }
    class FlickerLight {
        <<PointLight2D>>
    }
    class GearPickup {
        <<Area2D>>
    }
    class Grate {
        <<Node2D>>
        +open()
        +close()
    }
    class HeartPotion {
        <<Area2D>>
    }
    class HubLevel {
        +wire()
    }
    class Interactable {
        <<Area2D>>
        +interact()
    }
    class Level {
        <<Node2D>>
        +setup(game, p_kit)
        +default_data() Dictionary
        +wire()
        +title_point() Vector2
        +handle_action(_actions) bool
        +action_prompt() Dictionary
        +touch_actions() Array
        +hud_line() String
        +draw_hud(_ui)
        +notice_top() float
        +apply_quality(profile)
        +cell_center(cell) Vector2$
        +nodes_of(kind) Array
        +set_checkpoint(at)
        +respawn_player()
        +restart_after_death()
        +save_state() Dictionary
    }
    class MapExit {
    }
    class Npc {
        <<Node2D>>
    }
    class Pedestal {
        <<Node2D>>
    }
    class Pit {
        <<Node2D>>
        +rect() Rect2
    }
    class SignPost {
        <<Node2D>>
    }
    class TileKit {
        <<Facade>>
        +texture(path) Texture2D
        +particles(parent, at, fx, amount, lifetime) CPUParticles2D
    }
    class TownLevel {
        +default_data() Dictionary
        +wire()
        +open_gate()
    }
    class TriggerZone {
        <<Area2D>>
        +mark_fired()
    }
    TriggerZone <|-- CheckpointZone
    Level <|-- HubLevel
    TriggerZone <|-- MapExit
    Level <|-- TownLevel
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `Barrier` | `Node2D` | `src/world/barrier.gd` |
| `CheckpointZone` | `TriggerZone` | `src/world/checkpoint_zone.gd` |
| `Crusher` | `Node2D` | `src/world/crusher.gd` |
| `FlickerLight` | `PointLight2D` | `src/world/flicker_light.gd` |
| `GearPickup` | `Area2D` | `src/world/gear_pickup.gd` |
| `Grate` | `Node2D` | `src/world/grate.gd` |
| `HeartPotion` | `Area2D` | `src/world/heart_potion.gd` |
| `HubLevel` | `Level` | `src/world/hub_level.gd` |
| `Interactable` | `Area2D` | `src/world/interactable.gd` |
| `Level` | `Node2D` | `src/world/level.gd` |
| `MapExit` | `TriggerZone` | `src/world/map_exit.gd` |
| `Npc` | `Node2D` | `src/world/npc.gd` |
| `Pedestal` | `Node2D` | `src/world/pedestal.gd` |
| `Pit` | `Node2D` | `src/world/pit.gd` |
| `SignPost` | `Node2D` | `src/world/sign_post.gd` |
| `TileKit` | `RefCounted` | `src/world/tile_kit.gd` |
| `TownLevel` | `Level` | `src/world/town_level.gd` |
| `TriggerZone` | `Area2D` | `src/world/trigger_zone.gd` |

## `src/observers/` — Observadores (patrón Observer)

```mermaid
classDiagram
    class CameraShakeObserver {
        <<Observer>>
    }
    class SoundObserver {
        <<Observer>>
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `CameraShakeObserver` | `RefCounted` | `src/observers/camera_shake_observer.gd` |
| `SoundObserver` | `RefCounted` | `src/observers/sound_observer.gd` |

## `src/quality/` — Calidad de efectos (patrón Strategy)

```mermaid
classDiagram
    class HighQuality {
        <<Strategy>>
        +id() String
    }
    class LowQuality {
        <<Strategy>>
        +id() String
    }
    class QualityProfile {
        <<Strategy>>
        +create(index, presets) QualityProfile$
        +id() String
        +shadows() bool
        +particle_scale() float
    }
    QualityProfile <|-- HighQuality
    QualityProfile <|-- LowQuality
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `HighQuality` | `QualityProfile` | `src/quality/high_quality.gd` |
| `LowQuality` | `QualityProfile` | `src/quality/low_quality.gd` |
| `QualityProfile` | `RefCounted` | `src/quality/quality_profile.gd` |

## `src/camera/` — Cámara

```mermaid
classDiagram
    class CameraRig {
        <<Camera2D>>
        +set_bounds(pixels)
        +follow(node)
        +frame(at, zoom_factor, seconds)
        +shake(amount)
        +is_gliding() bool
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `CameraRig` | `Camera2D` | `src/camera/camera_rig.gd` |

## `src/fx/` — Efectos

```mermaid
classDiagram
    class GlyphSwing {
        <<Node2D>>
    }
    class NumberBurst {
        <<Node2D>>
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `GlyphSwing` | `Node2D` | `src/fx/glyph_swing.gd` |
| `NumberBurst` | `Node2D` | `src/fx/number_burst.gd` |

## `src/tests/` — Pruebas automáticas

```mermaid
classDiagram
    class RouteTour {
        <<RefCounted>>
        +run(arg)
    }
    class SelfTest {
        <<RefCounted>>
        +run()
    }
    class SqlLangTests {
        <<RefCounted>>
        +run_all(check)
    }
```

| Clase | Hereda de | Archivo |
|---|---|---|
| `RouteTour` | `RefCounted` | `src/tests/route_tour.gd` |
| `SelfTest` | `RefCounted` | `src/tests/self_test.gd` |
| `SqlLangTests` | `RefCounted` | `src/tests/sql_lang_tests.gd` |
