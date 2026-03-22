{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "node {{PLUGIN_DIR}}/scripts/session-start.js"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node {{PLUGIN_DIR}}/scripts/user-prompt-submit.js"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node {{PLUGIN_DIR}}/scripts/lifecycle-memory-review.js --event TaskCompleted"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node {{PLUGIN_DIR}}/scripts/lifecycle-memory-review.js --event Stop"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node {{PLUGIN_DIR}}/scripts/lifecycle-memory-review.js --event SessionEnd"
          }
        ]
      }
    ]
  }
}
