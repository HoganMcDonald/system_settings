#!/bin/bash
# Shared helpers for the bar pet. Sourced by pet_tick.sh, pet_action.sh,
# pet_popup.sh, pet_click.sh, pet_animate.sh.

STATE_DIR="${HOME}/.cache/sketchybar-pet"
STATE_FILE="${STATE_DIR}/state.json"
ANIM_LOCK="${STATE_DIR}/animating.lock"
COOLDOWN_SECONDS=300
DEATH_GRACE_SECONDS=7200
SPEECH_THROTTLE_SECONDS=600
SHAKE_THROTTLE_SECONDS=180
WANDER_MAX=80
NPC_LIFETIME_MIN=480
NPC_LIFETIME_RANGE=420

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

now() { date +%s; }
rand_between() { echo $(( $1 + RANDOM % ($2 - $1 + 1) )); }
roll() { [ $(( RANDOM % $1 )) -eq 0 ]; }

default_state() {
  local t
  t=$(now)
  jq -n --argjson t "$t" '{
    born_at: $t,
    stage: "egg",
    last_stage: "egg",
    adult_form: null,
    lineage: "eldritch",
    hunger: 100,
    happiness: 100,
    energy: 100,
    cleanliness: 100,
    last_tick: $t,
    last_fed: 0,
    last_played: 0,
    last_cleaned: 0,
    last_petted: 0,
    last_spoke: 0,
    last_shake: 0,
    wander_offset: 5,
    care_log: [],
    alive: true,
    died_at: null,
    grave_until: 0,
    npc: null,
    ai_enabled: true,
    claude: {
      session_active: false,
      session_started_at: 0,
      last_event_at: 0,
      current_tool: null,
      recent_failures: [],
      events_this_session: 0,
      long_session_announced: false,
      idle_announced: false,
      last_ai_call: 0
    }
  }'
}

# Add any new keys missing from older state files.
migrate_state() {
  local s="$1"
  echo "$s" | jq '
    .born_at        //= (now | floor) |
    .stage          //= "egg" |
    .last_stage     //= (.stage // "egg") |
    .adult_form     //= null |
    .lineage        //= "eldritch" |
    .hunger         = ((.hunger // 100)) |
    .happiness      = ((.happiness // 100)) |
    .energy         = ((.energy // 100)) |
    .cleanliness    = ((.cleanliness // 100)) |
    .last_tick      //= (now | floor) |
    .last_fed       //= 0 |
    .last_played    //= 0 |
    .last_cleaned   //= 0 |
    .last_petted    //= 0 |
    .last_spoke     //= 0 |
    .last_shake     //= 0 |
    .wander_offset  //= 5 |
    .care_log       //= [] |
    .alive          = (if .alive == null then true else .alive end) |
    .died_at        //= null |
    .grave_until    //= 0 |
    .npc            //= null |
    .ai_enabled     = (if .ai_enabled == null then true else .ai_enabled end) |
    .claude         //= {} |
    .claude.session_active         = (if .claude.session_active == null then false else .claude.session_active end) |
    .claude.session_started_at     //= 0 |
    .claude.last_event_at          //= 0 |
    .claude.current_tool           //= null |
    .claude.recent_failures        //= [] |
    .claude.events_this_session    //= 0 |
    .claude.long_session_announced = (if .claude.long_session_announced == null then false else .claude.long_session_announced end) |
    .claude.idle_announced         = (if .claude.idle_announced == null then false else .claude.idle_announced end) |
    .claude.last_ai_call           //= 0
  '
}

# Prune failure timestamps older than 10 min.
prune_failures() {
  local s="$1" t="$2"
  echo "$s" | jq --argjson t "$t" '
    .claude.recent_failures = (.claude.recent_failures | map(select(. >= ($t - 600))))
  '
}

read_state() {
  ensure_state_dir
  if [ ! -s "$STATE_FILE" ]; then
    default_state > "$STATE_FILE"
  fi
  migrate_state "$(cat "$STATE_FILE")"
}

write_state() {
  ensure_state_dir
  printf '%s\n' "$1" > "$STATE_FILE"
}

# ─── Lineage sprite tables ────────────────────────────────────────────

# sprite_for_stage <stage> <adult_form> [lineage]
sprite_for_stage() {
  local stage="$1" form="$2" lineage="${3:-eldritch}"
  if [ "$stage" = "grave" ]; then echo "🪦"; return; fi
  case "$lineage" in
    slime)
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "🫧" ;;
        baby)  echo "🟢" ;;
        teen)  echo "🦠" ;;
        adult|elder)
          case "$form" in
            communed) echo "🧚" ;;
            drifter)  echo "🐸" ;;
            awoken)   echo "👾" ;;
            *)        echo "🦠" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
    moss)
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "🌱" ;;
        baby)  echo "🐛" ;;
        teen)  echo "🐞" ;;
        adult|elder)
          case "$form" in
            communed) echo "🦋" ;;
            drifter)  echo "🐝" ;;
            awoken)   echo "🪲" ;;
            *)        echo "🐞" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
    machine)
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "💡" ;;
        baby)  echo "⚙️" ;;
        teen)  echo "🤖" ;;
        adult|elder)
          case "$form" in
            communed) echo "🛰️" ;;
            drifter)  echo "🛸" ;;
            awoken)   echo "🦾" ;;
            *)        echo "🤖" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
    flame)
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "✨" ;;
        baby)  echo "🕯️" ;;
        teen)  echo "🔥" ;;
        adult|elder)
          case "$form" in
            communed) echo "🌟" ;;
            drifter)  echo "☄️" ;;
            awoken)   echo "🌋" ;;
            *)        echo "🔥" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
    astral)
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "💫" ;;
        baby)  echo "⭐" ;;
        teen)  echo "🌟" ;;
        adult|elder)
          case "$form" in
            communed) echo "☀️" ;;
            drifter)  echo "🪐" ;;
            awoken)   echo "🌑" ;;
            *)        echo "🌟" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
    *) # eldritch
      case "$stage" in
        egg)   echo "🥚" ;;
        hatch) echo "🌀" ;;
        baby)  echo "👁" ;;
        teen)  echo "🦑" ;;
        adult|elder)
          case "$form" in
            communed) echo "🐙" ;;
            drifter)  echo "🪼" ;;
            awoken)   echo "👹" ;;
            *)        echo "🦑" ;;
          esac ;;
        *) echo "🥚" ;;
      esac ;;
  esac
}

stage_for_age() {
  local age="$1"
  if   [ "$age" -lt 14400 ];   then echo "egg"
  elif [ "$age" -lt 43200 ];   then echo "hatch"
  elif [ "$age" -lt 172800 ];  then echo "baby"
  elif [ "$age" -lt 432000 ];  then echo "teen"
  elif [ "$age" -lt 1209600 ]; then echo "adult"
  else                              echo "elder"
  fi
}

form_for_care() {
  local care="$1"
  if   awk -v c="$care" 'BEGIN{exit !(c >= 80)}'; then echo "communed"
  elif awk -v c="$care" 'BEGIN{exit !(c >= 40)}'; then echo "drifter"
  else                                                 echo "awoken"
  fi
}

mood_name() {
  local hunger="$1" happiness="$2" energy="$3" cleanliness="$4"
  local low_name="content" low_val=101
  for pair in "hunger:$hunger" "happiness:$happiness" "energy:$energy" "cleanliness:$cleanliness"; do
    local name="${pair%%:*}" val="${pair##*:}"
    if [ "$val" -lt "$low_val" ]; then low_val="$val"; low_name="$name"; fi
  done
  if [ "$low_val" -le 0 ];  then echo "death"; return; fi
  if [ "$low_val" -ge 75 ]; then echo "content"; return; fi
  echo "$low_name"
}

mood_glyph() {
  case "$(mood_name "$@")" in
    content)     echo "💖" ;;
    death)       echo "💀" ;;
    hunger)      echo "🍖" ;;
    happiness)   echo "🎈" ;;
    energy)      echo "💤" ;;
    cleanliness) echo "💩" ;;
    *)           echo "💖" ;;
  esac
}

stat_bar() {
  local v="$1"
  local filled=$(( v / 20 ))
  [ "$filled" -gt 5 ] && filled=5
  local bar="" i=0
  while [ "$i" -lt 5 ]; do
    if [ "$i" -lt "$filled" ]; then bar+="█"; else bar+="░"; fi
    i=$((i + 1))
  done
  echo "$bar"
}

# ─── Cyberdream palette ───────────────────────────────────────────────

PET_COLOR_TEXT=0xffffffff
PET_COLOR_GREEN=0xff5eff6b
PET_COLOR_YELLOW=0xfff1ff5e
PET_COLOR_ORANGE=0xffffbd5e
PET_COLOR_RED=0xffff6e5e
PET_COLOR_PURPLE=0xffbd5eff
PET_COLOR_PINK=0xffff5ea0
PET_COLOR_TEAL=0xff5ef1ff

color_for_low() {
  local low="$1"
  if   [ "$low" -ge 75 ]; then echo "$PET_COLOR_TEAL"
  elif [ "$low" -ge 50 ]; then echo "$PET_COLOR_GREEN"
  elif [ "$low" -ge 25 ]; then echo "$PET_COLOR_YELLOW"
  elif [ "$low" -gt 0 ];  then echo "$PET_COLOR_ORANGE"
  else                         echo "$PET_COLOR_RED"
  fi
}

# ─── Speech library ───────────────────────────────────────────────────

# Echoes a single speech line for a given mood. Adds variation by RANDOM.
speech_for() {
  local mood="$1" stage="$2"
  local lines=()
  case "$mood" in
    hunger)
      lines=(
        "i'm starving..."
        "feed me. now."
        "everything itches when i'm empty."
        "the void calls."
        "do you hear that? that's me. hungry."
      ) ;;
    happiness)
      lines=(
        "i'm bored."
        "play with me?"
        "the bar is so... still."
        "entertain my form."
      ) ;;
    energy)
      lines=(
        "...zzz..."
        "so tired."
        "my edges blur."
        "let me rest."
      ) ;;
    cleanliness)
      lines=(
        "i feel sticky."
        "scrub me, please."
        "something is growing on me."
        "this body is a swamp."
      ) ;;
    death)
      lines=(
        "the cold..."
        "remember me."
      ) ;;
    content|*)
      lines=(
        "the bar is humming today."
        "have you noticed the corners?"
        "i remember being water."
        "i saw something move in the dock."
        "you smell like coffee."
        "what year is it?"
        "i dreamed of cursors."
      ) ;;
  esac
  local idx=$((RANDOM % ${#lines[@]}))
  echo "${lines[$idx]}"
}

milestone_speech() {
  local stage="$1"
  case "$stage" in
    hatch)  echo "something stirs." ;;
    baby)   echo "i can see now." ;;
    teen)   echo "i'm changing." ;;
    adult)  echo "i have chosen a shape." ;;
    elder)  echo "i remember everything." ;;
    *)      echo "" ;;
  esac
}

# ─── NPC encounters ───────────────────────────────────────────────────

# Echoes "<species>:<sprite>:<flavor>" — pipe-separated for easy parsing.
npc_random() {
  local species=(
    "moonling:🌙:hums an old song"
    "jelly:🪼:drifts past, weightless"
    "bat:🦇:circles once, lands"
    "pilgrim:🕯:bows its tiny flame"
    "ghoul:👻:waves shyly"
    "snail:🐌:leaves a silver trail"
    "moth:🦋:flutters near your light"
  )
  local idx=$((RANDOM % ${#species[@]}))
  echo "${species[$idx]}"
}

# Returns "<stat>:<delta>" for clicking an npc by species.
npc_effect() {
  case "$1" in
    moonling) echo "energy:15" ;;
    jelly)    echo "happiness:10" ;;
    bat)      echo "energy:-5" ;;
    pilgrim)  echo "cleanliness:15" ;;
    ghoul)    echo "happiness:15" ;;
    snail)    echo "cleanliness:-10" ;;
    moth)     echo "happiness:5" ;;
    *)        echo "happiness:5" ;;
  esac
}

npc_farewell() {
  case "$1" in
    moonling) echo "moonling sang you a tide." ;;
    jelly)    echo "the jelly drifted on." ;;
    bat)      echo "the bat startled and fled." ;;
    pilgrim)  echo "the pilgrim blessed you." ;;
    ghoul)    echo "the ghoul phased away." ;;
    snail)    echo "the snail left a smear." ;;
    moth)     echo "the moth chased a pixel." ;;
    *)        echo "they're gone." ;;
  esac
}
