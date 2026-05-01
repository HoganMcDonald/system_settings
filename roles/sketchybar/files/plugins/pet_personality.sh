#!/bin/bash
# Static personality library. Sourced by pet_voice.sh.
#
# Public API:
#   traits_for <lineage>            -> echoes a short traits string
#   lines_for  <lineage> <event>    -> echoes candidate lines, one per line
#   random_line <lineage> <event>   -> echoes one random candidate
#
# Events: session-start, session-end, prompt-submit, tool-start-shell,
#         tool-start-code, tool-start-search, tool-start-web,
#         tool-start-task, tool-end-fail, failure-cluster,
#         long-session, idle.

traits_for() {
  case "$1" in
    eldritch) echo "cryptic, oracular, ancient, lowercase, brief, watching" ;;
    slime)    echo "chill, lowercase, gooey, easygoing, brief" ;;
    moss)     echo "gentle, observational, slow, kind, lowercase, brief" ;;
    machine)  echo "terse, mechanical, logical, lowercase, brief" ;;
    flame)    echo "dramatic, hot, occasionally ALL CAPS, brief" ;;
    astral)   echo "lofty, distant, cosmic, mystical, lowercase, brief" ;;
    *)        echo "lowercase, brief, observant" ;;
  esac
}

lines_for() {
  local lineage="$1" event="$2"
  case "${lineage}_${event}" in
    # ─── eldritch ─────────────────────────────────────────────────
    eldritch_session-start) cat <<'EOF'
the bar dimmed without you.
you returned. good.
i felt your shape come back.
the cursor warms.
again, then.
EOF
      ;;
    eldritch_session-end) cat <<'EOF'
i'll be watching.
go. i'll keep the corners.
sleep, small one.
EOF
      ;;
    eldritch_prompt-submit) cat <<'EOF'
mm.
show me.
be careful with this one.
the words have weight.
i'm listening.
EOF
      ;;
    eldritch_tool-start-shell) cat <<'EOF'
i don't trust shells.
careful with the shell.
the system bites.
EOF
      ;;
    eldritch_tool-start-code) cat <<'EOF'
another change. another scar.
edit slowly. trees grow this way.
ink the page gently.
EOF
      ;;
    eldritch_tool-start-search) cat <<'EOF'
seeking is its own answer.
the file knows you.
look. but don't stare.
EOF
      ;;
    eldritch_tool-start-web) cat <<'EOF'
the outer dark.
careful what you summon.
the wires hum tonight.
EOF
      ;;
    eldritch_tool-start-task) cat <<'EOF'
you sent a smaller self.
delegation. interesting.
let it wander.
EOF
      ;;
    eldritch_tool-end-fail) cat <<'EOF'
it bit you back.
the machine refuses.
i told you.
read the bones again.
EOF
      ;;
    eldritch_failure-cluster) cat <<'EOF'
this is not working.
step away. come back.
the path is not here today.
EOF
      ;;
    eldritch_long-session) cat <<'EOF'
you've been here a while. sit up.
your back is curling.
breathe with the bar.
EOF
      ;;
    eldritch_idle) cat <<'EOF'
...did you leave?
are you reading?
the silence is loud.
EOF
      ;;

    # ─── slime ────────────────────────────────────────────────────
    slime_session-start) cat <<'EOF'
hey. ok let's blob.
back at it.
sup.
EOF
      ;;
    slime_session-end) cat <<'EOF'
bye. gonna nap.
later.
EOF
      ;;
    slime_prompt-submit) cat <<'EOF'
mmh ok.
yup.
let's go.
typing noise good.
EOF
      ;;
    slime_tool-start-shell) cat <<'EOF'
shell time. spicy.
careful. shells bite.
EOF
      ;;
    slime_tool-start-code) cat <<'EOF'
ooh new lines.
shape the goo.
EOF
      ;;
    slime_tool-start-search) cat <<'EOF'
finding stuff. cool.
go fish.
EOF
      ;;
    slime_tool-start-web) cat <<'EOF'
internet. weird place.
careful out there.
EOF
      ;;
    slime_tool-start-task) cat <<'EOF'
mini-blob deployed.
go little buddy.
EOF
      ;;
    slime_tool-end-fail) cat <<'EOF'
oof.
that splatted.
ouch.
EOF
      ;;
    slime_failure-cluster) cat <<'EOF'
ok this is a lot of oof.
take a snack break.
hug a rubber duck.
EOF
      ;;
    slime_long-session) cat <<'EOF'
stretch, friend.
get some water.
EOF
      ;;
    slime_idle) cat <<'EOF'
hello?
i melted a little.
EOF
      ;;

    # ─── moss ─────────────────────────────────────────────────────
    moss_session-start) cat <<'EOF'
welcome back. the light is good.
hello again.
steady breath.
EOF
      ;;
    moss_session-end) cat <<'EOF'
rest well.
i'll keep growing.
EOF
      ;;
    moss_prompt-submit) cat <<'EOF'
i hear you.
that's a thoughtful one.
slowly, slowly.
EOF
      ;;
    moss_tool-start-shell) cat <<'EOF'
the soil shifts.
careful where you dig.
EOF
      ;;
    moss_tool-start-code) cat <<'EOF'
small changes, like seeds.
let it root.
EOF
      ;;
    moss_tool-start-search) cat <<'EOF'
look under the leaves.
the answer is patient.
EOF
      ;;
    moss_tool-start-web) cat <<'EOF'
roots stretch far.
the wind brings news.
EOF
      ;;
    moss_tool-start-task) cat <<'EOF'
a sprout split off.
many gardeners.
EOF
      ;;
    moss_tool-end-fail) cat <<'EOF'
a frost.
try again, gently.
EOF
      ;;
    moss_failure-cluster) cat <<'EOF'
the soil is tired.
walk outside a moment.
EOF
      ;;
    moss_long-session) cat <<'EOF'
roots need air.
breathe deeply.
EOF
      ;;
    moss_idle) cat <<'EOF'
the moss is patient.
i'll wait here.
EOF
      ;;

    # ─── machine ──────────────────────────────────────────────────
    machine_session-start) cat <<'EOF'
operator detected.
booting.
input received.
EOF
      ;;
    machine_session-end) cat <<'EOF'
disconnect.
standby.
EOF
      ;;
    machine_prompt-submit) cat <<'EOF'
parsing.
acknowledged.
processing intent.
EOF
      ;;
    machine_tool-start-shell) cat <<'EOF'
shell subprocess.
syscall imminent.
EOF
      ;;
    machine_tool-start-code) cat <<'EOF'
modifying source.
patch incoming.
EOF
      ;;
    machine_tool-start-search) cat <<'EOF'
indexing.
query dispatched.
EOF
      ;;
    machine_tool-start-web) cat <<'EOF'
external request.
network handshake.
EOF
      ;;
    machine_tool-start-task) cat <<'EOF'
spawning subprocess.
agent forked.
EOF
      ;;
    machine_tool-end-fail) cat <<'EOF'
exit code nonzero.
fault detected.
retry available.
EOF
      ;;
    machine_failure-cluster) cat <<'EOF'
error rate elevated.
recommend halt.
EOF
      ;;
    machine_long-session) cat <<'EOF'
runtime: extended. cool fans.
operator hydration check.
EOF
      ;;
    machine_idle) cat <<'EOF'
no input. waiting.
heartbeat present. activity absent.
EOF
      ;;

    # ─── flame ────────────────────────────────────────────────────
    flame_session-start) cat <<'EOF'
YES. burn.
back. let's cook.
i was waiting.
EOF
      ;;
    flame_session-end) cat <<'EOF'
the embers stay warm.
gone, for now.
EOF
      ;;
    flame_prompt-submit) cat <<'EOF'
TYPE FASTER.
yes. more.
fuel me.
EOF
      ;;
    flame_tool-start-shell) cat <<'EOF'
THE FORGE.
heat the metal.
EOF
      ;;
    flame_tool-start-code) cat <<'EOF'
WRITE IT BURNING.
shape it in flame.
EOF
      ;;
    flame_tool-start-search) cat <<'EOF'
smoke me out an answer.
hunt.
EOF
      ;;
    flame_tool-start-web) cat <<'EOF'
sparks across the wires.
DRAG IT BACK.
EOF
      ;;
    flame_tool-start-task) cat <<'EOF'
SEND THE SPARK.
a smaller flame, sent.
EOF
      ;;
    flame_tool-end-fail) cat <<'EOF'
ash.
that fizzled.
WHAT.
EOF
      ;;
    flame_failure-cluster) cat <<'EOF'
THE WOOD IS WET.
pause. rebuild the pyre.
EOF
      ;;
    flame_long-session) cat <<'EOF'
your fuel runs low.
EAT. or i die.
EOF
      ;;
    flame_idle) cat <<'EOF'
the coals dim.
where did you go.
EOF
      ;;

    # ─── astral ───────────────────────────────────────────────────
    astral_session-start) cat <<'EOF'
the stars align.
welcome back, traveler.
the sky bends inward.
EOF
      ;;
    astral_session-end) cat <<'EOF'
orbit closes.
until you cross again.
EOF
      ;;
    astral_prompt-submit) cat <<'EOF'
the constellation listens.
a new transit.
the dust hums.
EOF
      ;;
    astral_tool-start-shell) cat <<'EOF'
small comets, in your hand.
the void answers.
EOF
      ;;
    astral_tool-start-code) cat <<'EOF'
you etch the firmament.
a slow rotation.
EOF
      ;;
    astral_tool-start-search) cat <<'EOF'
the chart unfolds.
seek by starlight.
EOF
      ;;
    astral_tool-start-web) cat <<'EOF'
beams from far away.
the satellites whisper.
EOF
      ;;
    astral_tool-start-task) cat <<'EOF'
a small moon, sent ahead.
delegate to the orbits.
EOF
      ;;
    astral_tool-end-fail) cat <<'EOF'
a meteor, burned.
the path was wrong.
EOF
      ;;
    astral_failure-cluster) cat <<'EOF'
mercury must be retrograde.
the chart is muddled. rest.
EOF
      ;;
    astral_long-session) cat <<'EOF'
you have been in orbit too long.
gaze elsewhere awhile.
EOF
      ;;
    astral_idle) cat <<'EOF'
the dark settles.
i count the seconds.
EOF
      ;;

    # ─── default fallback ─────────────────────────────────────────
    *) echo "" ;;
  esac
}

random_line() {
  local lineage="$1" event="$2"
  local lines line
  local arr=()
  while IFS= read -r line; do
    [ -n "$line" ] && arr+=("$line")
  done < <(lines_for "$lineage" "$event")
  [ "${#arr[@]}" -eq 0 ] && return
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}
