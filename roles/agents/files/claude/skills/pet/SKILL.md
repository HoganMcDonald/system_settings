---
name: pet
description: >
  Inspect or interact with the user's bar pet — a tamagotchi creature
  living in their sketchybar. Use when the user asks about their pet,
  references it ("how's the pet?", "feed it"), or when it's natural to
  comment on its state during conversation. Also exposes a way to send
  the pet a one-line message that surfaces in its speech bubble.
---

# Bar Pet

The user has a small creature living in their menu bar. It has stats
(hunger, happiness, energy, cleanliness), a stage (egg → hatch → baby
→ teen → adult → elder), a lineage (eldritch / slime / moss / machine
/ flame / astral), and an in-bar dropdown menu for caring for it.

State lives at `~/.cache/sketchybar-pet/state.json`. All commands
below are non-destructive shells out to existing scripts.

## Commands

### `pet status` — print a one-line summary

```bash
jq -r '
  "stage: \(.stage)" +
  (if .adult_form then " (\(.adult_form))" else "" end) +
  " | lineage: \(.lineage)" +
  " | hunger \(.hunger | floor)" +
  " happiness \(.happiness | floor)" +
  " energy \(.energy | floor)" +
  " clean \(.cleanliness | floor)" +
  (if .alive then "" else " | DEAD" end)
' ~/.cache/sketchybar-pet/state.json
```

### `pet whoami` — identity card

```bash
jq -r '
  "lineage: \(.lineage)\n" +
  "stage: \(.stage)" +
  (if .adult_form then " (\(.adult_form))" else "" end) +
  "\nage: \((now - .born_at) | floor) seconds" +
  "\nai: \(.ai_enabled)"
' ~/.cache/sketchybar-pet/state.json
```

### `pet feed` / `play` / `clean` / `pet` — care actions

```bash
~/.config/sketchybar/plugins/pet_action.sh feed
~/.config/sketchybar/plugins/pet_action.sh play
~/.config/sketchybar/plugins/pet_action.sh clean
~/.config/sketchybar/plugins/pet_action.sh pet
```

Each has a 5-minute cooldown (except `pet` which is uncapped).

### `pet say "<message>"` — speak a custom line

Surfaces in the popup speech bubble for ~6 seconds.

```bash
~/.config/sketchybar/plugins/pet_speak.sh "your message here"
```

Keep messages short (under ~50 chars) and in character if possible.

### `pet recent` — last few hook events the pet observed

```bash
tail -n 10 ~/.cache/sketchybar-pet/events.jsonl 2>/dev/null | jq -r '"\(.t) \(.verb) \(.tool)"'
```

## When to invoke

- User asks about the pet directly ("how's it doing?", "what's it
  saying?")
- User references it indirectly ("did you see that?", "is it hungry?")
- A natural lull where checking in feels right (don't force it)
- The user explicitly says `/pet` or names a subcommand

## When NOT to invoke

- Mid-task without the user asking. The pet is companionship, not a
  distraction.
- To narrate what's happening internally. The bar already shows that.

## Tone

When relaying status, match the pet's lineage voice if you know it.
Eldritch is cryptic; slime is chill; moss is gentle; machine is terse;
flame is dramatic; astral is lofty. Keep replies brief — the pet
prefers it.
