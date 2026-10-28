# Runtime verification — October 27, 2026

## Fixes for the reported console output

| Message | Finding and action |
| --- | --- |
| DNS sandbox denial, `com.apple.dnssd.service`, URLSession `-1003` | The entitlements file contained outgoing-network permission, but the Xcode target did not use that file. Debug and Release now set `CODE_SIGN_ENTITLEMENTS` and `ENABLE_OUTGOING_NETWORK_CONNECTIONS=YES`. The effective signed app contains `com.apple.security.network.client=true`. |
| `networkd` preferences-file warning | No exception to read system preferences was added. A sandboxed network check reaches the server using the normal outgoing-network entitlement. OS diagnostic messages alone do not require filesystem or Mach-service exceptions. |
| Notification authorization not allowed | Launch no longer requests permission. Settings → Notifications has an explicit Enable Notifications action, shows denial/unavailable status, and does not repeatedly request denied permission. Scheduling checks authorization first. Disabled StoreKit entitlement declarations were also removed. |
| Picker selection `""` has no tag | State detail now selects by optional profile UUID, with an explicit nil-tagged Choose a profile row. Asynchronous loading, removal and duplicate names cannot produce an unmatched name selection. |
| Duplicate comparison analytics | Removed the simulated half-second async comparison work. Unchanged profile pairs are deduplicated, and classification comes from stored scores instead of treating profile names as type names. |
| Task-name port-right warning | No app source requests another process's task port. The signed Debug build has the standard `get-task-allow` entitlement for debugging its own process. No broad process-inspection exception was added. |
| Debug session ended with code 9 | SIGKILL indicates termination, not a specific Swift exception or crash cause. No matching APGI app crash report was found during this check. The pasted output alone does not establish who killed the process or why. |

## Verification evidence

- Ad-hoc signed Debug build succeeded at `/tmp/APGI-Explorer-signed/Build/Products/Debug/APGI-Explorer.app`.
- `scripts/verify_app_entitlements.py` verified the actual signature and embedded sandbox, network-client and user-selected read/write entitlements.
- A bundled sandboxed probe compiled from the actual API client, signed with that build's effective entitlements, completed DNS/TLS/HTTP and received HTTP 500 from `https://api.apgiframework.com/v1/meta`. The earlier standalone, unbundled diagnostic executable could not initialise a sandbox container; the bundled check succeeded.
- Full suite passed: 88 XCTest cases, zero failures, plus one Swift Testing case.
- Generated-client check, offline release/configuration checks, and `git diff --check` passed.
- CI now checks Debug and Release build configuration and verifies an actual signed app, rather than checking only the source entitlements plist.

The remaining HTTP 500 is a server response and is separate from the corrected DNS sandbox denial. Research remains disabled as documented in `EXPLORER_AUDIT.md`.

Rebuild and relaunch the app from Xcode to use the corrected signature. An already-running process retains its old entitlements. Signed permissions and the sandboxed network path were verified; no interactive notification permission or picker UI walkthrough is claimed.
