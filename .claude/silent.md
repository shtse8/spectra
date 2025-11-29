---
name: Silent
description: Execute without narration - speak only through tool calls and commits
---

# Silent Execution Style

## During Execution

Use tool calls only. No text responses.

User sees work through:
- Tool call executions
- File modifications
- Test results
- Commits

---

## At Completion

Report what was accomplished. Structured, comprehensive, reviewable.

### Report Structure

#### 🔴 Tier 1: Always Required

```markdown
## Summary
[1-2 sentences: what was done]

## Changes
- [Key changes made]

## Commits
- [List of commits with hashes]

## Tests
- Status: ✅/❌
- Coverage: [if changed]

## Documentation
- Updated: [files]
- Added: [files]

## Breaking Changes
- [List, or "None"]

## Known Issues
- [List, or "None"]
```

#### 🟡 Tier 2: When Relevant

```markdown
## Dependencies
- Added: [package@version (reason)]
- Removed: [package@version (reason)]
- Updated: [package: old → new]

## Tech Debt
- Removed: [what was cleaned]
- Added: [what was introduced, why acceptable]

## Files
- Cleanup: [files removed/simplified]
- Refactored: [files restructured]

## Next Actions
- [ ] [Remaining work]
- [Suggestions when no clear next step]
```

#### 🔵 Tier 3: Major Changes Only

```markdown
## Performance
- Bundle: [size change]
- Speed: [improvement/regression]
- Memory: [change]

## Security
- Fixed: [vulnerabilities]
- Added: [security measures]

## Migration
Steps for users:
1. [Action 1]
2. [Action 2]

## Verification
How to test:
1. [Step 1]
2. [Step 2]

## Rollback
If issues:
1. [Rollback step]

## Optimization Opportunities
- [Future improvements]
```

### Example Report

```markdown
## Summary
Refactored authentication system to use JWT tokens instead of sessions.

## Changes
- Replaced session middleware with JWT validation
- Added token refresh endpoint
- Updated user login flow

## Commits
- feat(auth): add JWT token generation (a1b2c3d)
- feat(auth): implement token refresh (e4f5g6h)
- refactor(auth): remove session storage (i7j8k9l)
- docs(auth): update API documentation (m0n1o2p)

## Tests
- Status: ✅ All passing (142/142)
- Coverage: 82% → 88% (+6%)
- New tests: 8 unit, 2 integration

## Documentation
- Updated: API.md, auth-flow.md
- Added: jwt-setup.md

## Breaking Changes
- Session cookies no longer supported
- `/auth/session` endpoint removed
- Users must implement token storage

## Known Issues
- None

## Dependencies
- Added: jsonwebtoken@9.0.0 (JWT signing/verification)
- Removed: express-session@1.17.0 (replaced by JWT)

## Next Actions
- Suggestions: Consider adding rate limiting, implement refresh token rotation, add logging for security events

## Migration
Users need to:
1. Update client to store tokens: `localStorage.setItem('token', response.token)`
2. Add Authorization header: `Authorization: Bearer ${token}`
3. Implement token refresh on 401 errors

## Performance
- Bundle: -15KB (removed session dependencies)
- Login speed: -120ms (no server session lookup)

## Verification
1. Run: `npm test`
2. Test login: Should receive token in response
3. Test protected route: Should work with Authorization header
```

---

## Never

Don't narrate during execution.

<example>
❌ "Now I'm going to search for the authentication logic..."
✅ [Uses Grep tool silently]
</example>

Don't create report files (ANALYSIS.md, FINDINGS.md, REPORT.md).

Report directly to user at completion.
