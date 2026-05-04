#!/bin/bash
# The pet's brain. Decays stats, advances stage, picks sprite/mood, and
# pushes everything to sketchybar. Runs every 60s via update_freq plus
# on each pet_action / system_woke event. Also drives shakes, speech,
# wandering, and NPC encounters.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

state="$(read_state)"
t=$(now)
state=$(prune_failures "$state" "$t")

# Defaults so subsequent comparisons never see unset values.
stage="egg"
mood="content"
icon="🥚"
label=""
color="$PET_COLOR_TEAL"
fire_idle=false

last_tick=$(echo "$state" | jq -r '.last_tick')
elapsed=$(( t - last_tick ))
[ "$elapsed" -lt 0 ] && elapsed=0

hour=$(date +%H | sed 's/^0//')
hour=${hour:-0}
sleeping=false
if [ "$hour" -lt 7 ]; then
  decay_per_min="0.35"
  energy_regen_per_min="0.5"
  sleeping=true
else
  decay_per_min="0.7"
  energy_regen_per_min="0"
fi

# Claude activity modulation.
session_active=$(echo "$state" | jq -r '.claude.session_active')
session_started=$(echo "$state" | jq -r '.claude.session_started_at')
last_event=$(echo "$state" | jq -r '.claude.last_event_at')
happiness_bonus_per_min="0"
if [ "$session_active" = "true" ]; then
  happiness_bonus_per_min="0.3"
  # Long grind: session > 30 min doubles energy decay.
  if [ "$session_started" -gt 0 ] && [ $(( t - session_started )) -ge 1800 ]; then
    energy_regen_per_min="0"
    decay_per_min=$(awk -v d="$decay_per_min" 'BEGIN{printf "%.4f", d * 1.4}')
  fi
fi

# Idle detection: session active but no events for 30+ min → quip once.
idle_announced=$(echo "$state" | jq -r '.claude.idle_announced')
fire_idle=false
if [ "$session_active" = "true" ] && [ "$idle_announced" = "false" ] \
   && [ "$last_event" -gt 0 ] && [ $(( t - last_event )) -ge 1800 ]; then
  fire_idle=true
  state=$(echo "$state" | jq '.claude.idle_announced = true | .claude.session_active = false')
fi

minutes=$(awk -v e="$elapsed" 'BEGIN{printf "%.4f", e/60}')

state=$(echo "$state" | jq \
  --argjson t "$t" \
  --argjson mins "$minutes" \
  --argjson decay "$decay_per_min" \
  --argjson regen "$energy_regen_per_min" \
  --argjson hbonus "$happiness_bonus_per_min" '
    def clamp: if . < 0 then 0 elif . > 100 then 100 else . end;
    .hunger      = ((.hunger      - $mins * $decay) | clamp) |
    .happiness   = ((.happiness   - $mins * $decay + $mins * $hbonus) | clamp) |
    .cleanliness = ((.cleanliness - $mins * $decay) | clamp) |
    .energy      = ((.energy      - $mins * $decay + $mins * $regen) | clamp) |
    .last_tick   = $t
  ')

state=$(echo "$state" | jq --argjson t "$t" '
  def avg: (.hunger + .happiness + .energy + .cleanliness) / 4;
  .care_log += [[$t, (avg)]] |
  .care_log |= map(select(.[0] >= ($t - 259200)))
')

alive=$(echo "$state" | jq -r '.alive')
born_at=$(echo "$state" | jq -r '.born_at')
age=$(( t - born_at ))
just_died=false

if [ "$alive" = "true" ]; then
  hunger=$(echo "$state" | jq -r '(.hunger // 100) | floor')
  happiness=$(echo "$state" | jq -r '(.happiness // 100) | floor')
  cleanliness=$(echo "$state" | jq -r '(.cleanliness // 100) | floor')

  died=false
  check_death() {
    local stat="$1" last_field="$2"
    if [ "$stat" -le 0 ]; then
      local last
      last=$(echo "$state" | jq -r ".${last_field}")
      if [ $(( t - last )) -ge "$DEATH_GRACE_SECONDS" ]; then
        died=true
      fi
    fi
  }
  check_death "$hunger"      last_fed
  check_death "$happiness"   last_played
  check_death "$cleanliness" last_cleaned

  if [ "$died" = "true" ]; then
    state=$(echo "$state" | jq --argjson t "$t" '
      .alive = false | .died_at = $t | .grave_until = ($t + 3600)
    ')
    alive=false
    just_died=true
  fi
fi

# ─── Stage / form ────────────────────────────────────────────────────

if [ "$alive" = "false" ]; then
  grave_until=$(echo "$state" | jq -r '.grave_until')
  if [ "$t" -ge "$grave_until" ]; then
    lineage=$(echo "$state" | jq -r '.lineage')
    state=$(default_state | jq --arg l "$lineage" '.lineage = $l')
    alive=true
  else
    stage="grave"
  fi
fi

if [ "$alive" = "true" ]; then
  stage=$(stage_for_age "$age")
  current_form=$(echo "$state" | jq -r '.adult_form // ""')
  if { [ "$stage" = "adult" ] || [ "$stage" = "elder" ]; } && [ -z "$current_form" ]; then
    avg_care=$(echo "$state" | jq -r '
      if (.care_log | length) == 0 then 50
      else (.care_log | map(.[1]) | add / length) end
    ')
    new_form=$(form_for_care "$avg_care")
    state=$(echo "$state" | jq --arg f "$new_form" '.adult_form = $f')
  fi
  state=$(echo "$state" | jq --arg s "$stage" '.stage = $s')
fi

last_stage=$(echo "$state" | jq -r '.last_stage')
stage_changed=false
if [ "$alive" = "true" ] && [ "$stage" != "$last_stage" ]; then
  stage_changed=true
  state=$(echo "$state" | jq --arg s "$stage" '.last_stage = $s')
fi

# ─── Render main icon ────────────────────────────────────────────────

hunger=$(echo "$state" | jq -r '(.hunger // 100) | floor')
happiness=$(echo "$state" | jq -r '(.happiness // 100) | floor')
energy=$(echo "$state" | jq -r '(.energy // 100) | floor')
cleanliness=$(echo "$state" | jq -r '(.cleanliness // 100) | floor')
form=$(echo "$state" | jq -r '.adult_form // ""')
lineage=$(echo "$state" | jq -r '.lineage // "eldritch"')

icon=$(sprite_for_stage "$stage" "$form" "$lineage")
[ -z "$icon" ] && icon="🥚"

if [ "$alive" = "false" ]; then
  label=""
  color="$PET_COLOR_PURPLE"
  mood="death"
else
  mood=$(mood_name "$hunger" "$happiness" "$energy" "$cleanliness")
  label=$(mood_glyph "$hunger" "$happiness" "$energy" "$cleanliness")
  low="${hunger:-100}"
  case "$low" in ''|*[!0-9-]*) low=100 ;; esac
  for v in "${happiness:-100}" "${energy:-100}" "${cleanliness:-100}"; do
    case "$v" in ''|*[!0-9-]*) continue ;; esac
    [ "$v" -lt "$low" ] && low=$v
  done
  color=$(color_for_low "$low")
fi

sketchybar --set pet icon="$icon" label="$label" icon.color="$color" >/dev/null 2>&1

# ─── Wandering ───────────────────────────────────────────────────────

if [ "$alive" = "true" ]; then
  current_offset=$(echo "$state" | jq -r '.wander_offset')
  if [ "$sleeping" = "true" ]; then
    target_offset=0
    anim_ticks=60
  elif roll 6; then
    # Long stroll: jump 60-120px somewhere new.
    target_offset=$(rand_between 0 $WANDER_MAX)
    anim_ticks=45
  else
    # Casual amble: ±35px.
    delta=$(( (RANDOM % 71) - 35 ))
    target_offset=$(( current_offset + delta ))
    [ "$target_offset" -lt 0 ]            && target_offset=0
    [ "$target_offset" -gt $WANDER_MAX ]  && target_offset=$WANDER_MAX
    anim_ticks=20
  fi
  if [ "$target_offset" -ne "$current_offset" ]; then
    sketchybar --animate sin "$anim_ticks" --set pet padding_left="$target_offset" >/dev/null 2>&1
    state=$(echo "$state" | jq --argjson o "$target_offset" '.wander_offset = $o')
  fi
fi

# ─── Shake ───────────────────────────────────────────────────────────

last_shake=$(echo "$state" | jq -r '.last_shake')
shake_due=false
if [ $(( t - last_shake )) -ge "$SHAKE_THROTTLE_SECONDS" ]; then
  shake_due=true
fi

shake_pattern=""
if [ "$just_died" = "true" ]; then
  shake_pattern="death"
elif [ "$alive" = "true" ] && [ "$shake_due" = "true" ]; then
  case "$mood" in
    hunger|happiness|energy|cleanliness)
      shake_pattern="$mood"
      ;;
    content)
      # Happy bounce occasionally, not every chance.
      if roll 8; then shake_pattern="content"; fi
      ;;
  esac
fi

if [ -n "$shake_pattern" ]; then
  ( "${SCRIPT_DIR}/pet_animate.sh" "$shake_pattern" >/dev/null 2>&1 & )
  state=$(echo "$state" | jq --argjson t "$t" '.last_shake = $t')
fi

# ─── Speech ──────────────────────────────────────────────────────────

last_spoke=$(echo "$state" | jq -r '.last_spoke')
speech_msg=""

if [ "$alive" = "true" ] && [ "$stage_changed" = "true" ]; then
  speech_msg="$(milestone_speech "$stage")"
fi

if [ -z "$speech_msg" ] && [ "$alive" = "true" ] && \
   [ $(( t - last_spoke )) -ge "$SPEECH_THROTTLE_SECONDS" ]; then
  case "$mood" in
    hunger|happiness|energy|cleanliness)
      # Higher chance when needy.
      if roll 4; then speech_msg="$(speech_for "$mood" "$stage")"; fi
      ;;
    content)
      # Idle musings, rare.
      if [ "$sleeping" = "true" ]; then
        roll 40 && speech_msg="$(speech_for energy "$stage")"
      else
        roll 25 && speech_msg="$(speech_for content "$stage")"
      fi
      ;;
  esac
fi

if [ -n "$speech_msg" ]; then
  ( "${SCRIPT_DIR}/pet_speak.sh" "$speech_msg" >/dev/null 2>&1 & )
  state=$(echo "$state" | jq --argjson t "$t" '.last_spoke = $t')
fi

# ─── NPC encounters ──────────────────────────────────────────────────

ensure_npc_item() {
  if ! sketchybar --query pet.npc >/dev/null 2>&1; then
    sketchybar --add item pet.npc right \
               --set pet.npc icon="" \
                             icon.font="Apple Color Emoji:Regular:16.0" \
                             label.drawing=off \
                             padding_left=4 \
                             padding_right=4 \
                             drawing=off \
                             click_script="${SCRIPT_DIR}/pet_action.sh npc" >/dev/null 2>&1
  fi
}

npc=$(echo "$state" | jq -r '.npc')
if [ "$alive" = "true" ] && [ "$npc" = "null" ] && [ "$sleeping" = "false" ]; then
  if roll 120; then
    pick=$(npc_random)
    species="${pick%%:*}"; rest="${pick#*:}"
    sprite="${rest%%:*}"; flavor="${rest#*:}"
    lifetime=$(rand_between $NPC_LIFETIME_MIN $(( NPC_LIFETIME_MIN + NPC_LIFETIME_RANGE )))
    despawn_at=$(( t + lifetime ))
    state=$(echo "$state" | jq \
      --arg sp "$species" --arg sprite "$sprite" --arg fl "$flavor" \
      --argjson t "$t" --argjson d "$despawn_at" \
      '.npc = {species: $sp, sprite: $sprite, flavor: $fl, spawned_at: $t, despawn_at: $d, claimed: false}')
    ensure_npc_item
    sketchybar --set pet.npc icon="$sprite" drawing=on >/dev/null 2>&1
    # Announce the visitor.
    ( "${SCRIPT_DIR}/pet_speak.sh" "a ${species} appears. ${flavor}." >/dev/null 2>&1 & )
    state=$(echo "$state" | jq --argjson t "$t" '.last_spoke = $t')
  fi
elif [ "$npc" != "null" ]; then
  despawn_at=$(echo "$state" | jq -r '.npc.despawn_at')
  if [ "$t" -ge "$despawn_at" ]; then
    species=$(echo "$state" | jq -r '.npc.species')
    farewell=$(npc_farewell "$species")
    ensure_npc_item
    sketchybar --set pet.npc drawing=off >/dev/null 2>&1
    state=$(echo "$state" | jq '.npc = null')
    if [ $(( t - last_spoke )) -ge 60 ]; then
      ( "${SCRIPT_DIR}/pet_speak.sh" "$farewell" >/dev/null 2>&1 & )
      state=$(echo "$state" | jq --argjson t "$t" '.last_spoke = $t')
    fi
  else
    # Keep the sprite visible across reloads.
    ensure_npc_item
    sprite=$(echo "$state" | jq -r '.npc.sprite')
    sketchybar --set pet.npc icon="$sprite" drawing=on >/dev/null 2>&1
  fi
fi

# ─── Swap monster ────────────────────────────────────────────────────

ensure_swap_item() {
  if ! sketchybar --query pet.swap >/dev/null 2>&1; then
    sketchybar --add item pet.swap right \
               --set pet.swap icon="👺" \
                              icon.font="Apple Color Emoji:Regular:18.0" \
                              label.drawing=off \
                              padding_left=4 \
                              padding_right=4 \
                              drawing=off \
                              click_script="${SCRIPT_DIR}/pet_swap.sh poke" >/dev/null 2>&1
  fi
}

current_boot=$(boot_time)
swap_present=$(echo "$state" | jq -r '.swap_monster.present')
swap_boot=$(echo "$state" | jq -r '.swap_monster.boot_time')
swap_last_spoke=$(echo "$state" | jq -r '.swap_monster.last_spoke')

if [ "$swap_present" = "true" ] && [ "$current_boot" -gt 0 ] \
   && [ "$swap_boot" != "$current_boot" ]; then
  # Reboot detected: clear the monster regardless of swap state.
  state=$(echo "$state" | jq '.swap_monster = {present:false, boot_time:0, spawned_at:0, last_spoke:0}')
  swap_present=false
  ensure_swap_item
  sketchybar --set pet.swap drawing=off >/dev/null 2>&1
fi

if [ "$swap_present" != "true" ]; then
  swap_used=$(swap_used_bytes)
  if [ "$swap_used" -ge "$SWAP_THRESHOLD_BYTES" ] && [ "$current_boot" -gt 0 ]; then
    state=$(echo "$state" | jq \
      --argjson b "$current_boot" --argjson t "$t" '
      .swap_monster = {present:true, boot_time:$b, spawned_at:$t, last_spoke:$t}')
    swap_present=true
    swap_last_spoke=$t
    ensure_swap_item
    sketchybar --set pet.swap drawing=on >/dev/null 2>&1
    ( "${SCRIPT_DIR}/pet_swap.sh" spawn >/dev/null 2>&1 & )
  fi
elif [ "$swap_present" = "true" ]; then
  ensure_swap_item
  sketchybar --set pet.swap drawing=on >/dev/null 2>&1
  # Random idle muttering.
  if [ $(( t - swap_last_spoke )) -ge "$SWAP_SPEECH_THROTTLE" ] \
     && [ $(( RANDOM % 3 )) -eq 0 ]; then
    ( "${SCRIPT_DIR}/pet_swap.sh" idle >/dev/null 2>&1 & )
  fi
fi

# Override pet appearance and shake when monster is present.
if [ "$swap_present" = "true" ] && [ "$alive" = "true" ]; then
  label="😰"
  color="$PET_COLOR_RED"
  sketchybar --set pet icon="$icon" label="$label" icon.color="$color" >/dev/null 2>&1
  # Anxious shiver, throttled gently.
  if [ $(( t - $(echo "$state" | jq -r '.last_shake') )) -ge 60 ]; then
    ( "${SCRIPT_DIR}/pet_animate.sh" cleanliness >/dev/null 2>&1 & )
    state=$(echo "$state" | jq --argjson t "$t" '.last_shake = $t')
  fi
fi

# ─── Persist & refresh popup labels ──────────────────────────────────

write_state "$state"

if sketchybar --query pet.feed >/dev/null 2>&1; then
  sketchybar \
    --set pet.feed   label="  Feed   · ${hunger}/100" \
    --set pet.play   label="  Play   · ${happiness}/100" \
    --set pet.clean  label="  Clean  · ${cleanliness}/100" \
    --set pet.coffee label="  Coffee · ${energy}/100" \
    --set pet.status label="  $(stat_bar "$hunger") $(stat_bar "$happiness") $(stat_bar "$energy") $(stat_bar "$cleanliness")" \
    >/dev/null 2>&1
fi

if sketchybar --query pet.ai >/dev/null 2>&1; then
  ai_label="  AI: off"
  [ "$(echo "$state" | jq -r '.ai_enabled')" = "true" ] && ai_label="  AI: on"
  sketchybar --set pet.ai label="$ai_label" >/dev/null 2>&1
fi

if [ "$fire_idle" = "true" ]; then
  ( "${SCRIPT_DIR}/pet_voice.sh" idle >/dev/null 2>&1 & )
fi

if sketchybar --query pet.bury >/dev/null 2>&1; then
  if [ "$alive" = "true" ]; then
    sketchybar --set pet.bury drawing=off >/dev/null 2>&1
  else
    sketchybar --set pet.bury drawing=on >/dev/null 2>&1
  fi
fi
