#!/usr/bin/env node
// notion_query.js — query Notion via mcp-remote and return results as JSON
//
// Usage: node notion_query.js <tool> [params-json]
//
// Tools:
//   recent-meetings <minutes>   — meeting notes modified in last N minutes (default 60)
//   search          <query>     — semantic search over workspace
//   fetch           <url-or-id> — fetch full page content
//
// Exits 0 on success (JSON to stdout).
// Exits 2 with AUTH_REQUIRED on stderr when re-authentication is needed.

import { spawn } from 'child_process'
import { createInterface } from 'readline'
import { randomUUID } from 'crypto'

const [,, tool, ...rest] = process.argv

if (!tool) {
  console.error('Usage: node notion_query.js <tool> [params...]')
  process.exit(1)
}

function buildCall(tool, args) {
  switch (tool) {
    case 'recent-meetings': {
      const minutes = parseInt(args[0] || '60', 10)
      // Fetch recent meetings and filter client-side by last edited time
      return {
        name: 'notion-query-meeting-notes',
        arguments: {},
        _filterMinutes: minutes
      }
    }
    case 'search':
      return {
        name: 'notion-search',
        arguments: { query: args[0] || '', query_type: 'internal' }
      }
    case 'fetch':
      return {
        name: 'notion-fetch',
        arguments: { url: args[0] }
      }
    default:
      console.error(`Unknown tool: ${tool}`)
      process.exit(1)
  }
}

const call = buildCall(tool, rest)
const filterMinutes = call._filterMinutes

const mcpRemote = spawn('npx', ['-y', 'mcp-remote', 'https://mcp.notion.com/mcp'], {
  stdio: ['pipe', 'pipe', 'pipe'],
  env: { ...process.env }
})

let initialized = false
const callId = randomUUID()

const timeout = setTimeout(() => {
  console.error('AUTH_REQUIRED: mcp-remote timed out — run: npx -y mcp-remote https://mcp.notion.com/mcp')
  mcpRemote.kill()
  process.exit(2)
}, 30000)

mcpRemote.stderr.on('data', (data) => {
  const msg = data.toString()
  // Only bail if a browser auth URL is actually being presented
  if (msg.includes('Open this URL') || msg.includes('open your browser') ||
      msg.match(/https?:\/\/[^\s]*(oauth|authorize|callback)[^\s]*/i)) {
    console.error('AUTH_REQUIRED: ' + msg.trim())
    clearTimeout(timeout)
    mcpRemote.kill()
    process.exit(2)
  }
})

const rl = createInterface({ input: mcpRemote.stdout })

rl.on('line', (line) => {
  if (!line.trim()) return
  let msg
  try { msg = JSON.parse(line) } catch { return }

  // Wait for initialize response before sending tool call
  if (!initialized && msg.id === 'init') {
    initialized = true
    mcpRemote.stdin.write(JSON.stringify({
      jsonrpc: '2.0',
      id: callId,
      method: 'tools/call',
      params: { name: call.name, arguments: call.arguments }
    }) + '\n')
    return
  }

  if (msg.id === callId) {
    clearTimeout(timeout)
    if (msg.error) {
      console.error('MCP error:', JSON.stringify(msg.error))
      mcpRemote.kill()
      process.exit(1)
    }

    let result = msg.result

    // Client-side time filter for recent-meetings
    if (filterMinutes && result?.content?.[0]?.text) {
      try {
        const since = new Date(Date.now() - filterMinutes * 60 * 1000)
        const parsed = JSON.parse(result.content[0].text)
        if (parsed.results) {
          parsed.results = parsed.results.filter(m => {
            const edited = m['Last edited time'] || m['Created time']
            return edited && new Date(edited) >= since
          })
          result = { content: [{ type: 'text', text: JSON.stringify(parsed, null, 2) }] }
        }
      } catch {}
    }

    console.log(JSON.stringify(result, null, 2))
    mcpRemote.kill()
    process.exit(0)
  }
})

// Send initialize
mcpRemote.stdin.write(JSON.stringify({
  jsonrpc: '2.0',
  id: 'init',
  method: 'initialize',
  params: {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'nanobot-notion', version: '1.0.0' }
  }
}) + '\n')

mcpRemote.on('close', (code) => {
  clearTimeout(timeout)
  if (code !== 0 && code !== null) process.exit(code)
})
