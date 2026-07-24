import type { Plugin } from "@opencode-ai/plugin"

const stateScript = `${process.env.HOME}/.config/zsh/bin/opencode-session-state`

export default (async () => {
  const update = async (status: "working" | "waiting" | "end") => {
    if (!process.env.TMUX) return

    const process = Bun.spawn([stateScript, status], {
      stdout: "ignore",
      stderr: "ignore",
    })
    await process.exited
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        await update(event.properties.status.type === "idle" ? "waiting" : "working")
      } else if (event.type === "session.idle") {
        await update("waiting")
      } else if (event.type === "session.deleted") {
        await update("end")
      }
    },
  }
}) satisfies Plugin
