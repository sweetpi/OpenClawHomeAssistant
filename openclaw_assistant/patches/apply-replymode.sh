#!/bin/bash
set -e

echo "Applying replyMode tool-only patches..."

# Patch 1: Add replyMode to zod schema in io-*.js
SCHEMA_FILE=$(find /usr/lib/node_modules/openclaw/dist/ -name "io-*.js" -path "*/openclaw/dist/*" | head -1)
if [ -n "$SCHEMA_FILE" ] && grep -q 'blockStreamingDefault' "$SCHEMA_FILE" && ! grep -q 'replyMode' "$SCHEMA_FILE"; then
  sed -i 's/blockStreamingDefault: z\.union(\[z\.literal("off"), z\.literal("on")\])\.optional(),/replyMode: z.enum(["auto", "tool-only"]).optional(),\n\tblockStreamingDefault: z.union([z.literal("off"), z.literal("on")]).optional(),/' "$SCHEMA_FILE"
  echo "  Patched schema: $SCHEMA_FILE"
else
  echo "  Schema already patched or file not found"
fi

# Patch 2: Find dispatch file and patch onBlockReply
DISPATCH_FILE=$(find /usr/lib/node_modules/openclaw/dist/ -name "dispatch-*.js" -not -name "dispatch-acp*" | head -1)
if [ -n "$DISPATCH_FILE" ] && ! grep -q 'tool-only' "$DISPATCH_FILE"; then
  # onBlockReply: suppress all streaming blocks in tool-only mode
  sed -i 's/onBlockReply: (payload, context) => {$/onBlockReply: (payload, context) => {\n\t\t\t\tif ((cfg.agents?.defaults?.replyMode ?? "auto") === "tool-only") return;/' "$DISPATCH_FILE"
  echo "  Patched onBlockReply: $DISPATCH_FILE"
else
  echo "  Dispatch already patched or file not found"
fi

echo "replyMode tool-only patches applied successfully"
