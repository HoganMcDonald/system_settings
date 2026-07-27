import type { Plugin } from "@opencode-ai/plugin"

const stateScript = `${process.env.HOME}/.config/zsh/bin/opencode-session-state`

export default (async () => {
  const update = async (status: "idle" | "working" | "waiting" | "end") => {
    if (!process.env.TMUX) return

    const child = Bun.spawn([stateScript, status], {
      stdout: "ignore",
      stderr: "ignore",
    })
    await child.exited
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        await update(event.properties.status.type === "idle" ? "waiting" : "working")
      } else if (event.type === "session.created") {
        await update("idle")
      } else if (event.type === "session.idle") {
        await update("waiting")
      } else if (event.type === "permission.updated") {
        await update("waiting")
      } else if (event.type === "permission.replied") {
        await update("working")
      } else if (event.type === "session.deleted") {
        await update("end")
      }
    },
  }
}) satisfies Plugin
