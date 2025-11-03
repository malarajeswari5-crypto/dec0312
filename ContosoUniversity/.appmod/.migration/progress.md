# Migration progress: Plaintext Credential to Secure Credentials (Azure Key Vault)

## Important Guideline

1. When you use terminal command tool, never input a long command with multiple lines, always use a single line command.
2. When performing semantic or intent-based searches, DO NOT search content from `.appmod/` folder.
3. Never create a new project in the solution, always use the existing project to add new files or update the existing files.
4. Minimize code changes: update only what's necessary for the migration.
5. Add New Package References to Projects following the migration plan guidelines.
6. Task tracking: update this file in real time as tasks progress.

## Pre-migration fixes
- [X] Fix System.Memory binding redirect and add explicit DLL references (compilation error resolved)

## Git / Branching tasks
- [X] Check git status (no uncommitted changes to stash from main codebase)
- [X] Create branch `appmod/dotnet-migration-PlaintextCredential-to-SecureCredentials-20251102175521`

## Migration tasks
- [ ] Add `KeyVaultUri` to `Web.config` appSettings (non-secret)
- [ ] Add packages `Azure.Security.KeyVault.Secrets` and `Azure.Identity` to project via legacy package flow
- [ ] Create `Services/KeyVaultSecretProvider.cs` to encapsulate Key Vault logic
- [ ] Modify `Data/SchoolContextFactory.cs` to use Key Vault for `DefaultConnection` (fallback to ConfigurationManager)
- [ ] Update any other code locations that read secrets from `Web.config` to prefer Key Vault (if any discovered)
- [ ] Run CVE check for added packages and remediate if needed
- [ ] Run build and fix compilation errors
- [ ] Commit all changes after each completed task with concise messages

## Validation
- [ ] Confirm application builds successfully
- [ ] Confirm no plaintext secrets remain in code files

## Notes
- System.Memory binding redirect updated from 4.0.1.2 to 4.5.4.0
- Added explicit references for System.Memory, System.Buffers, System.Runtime.CompilerServices.Unsafe, System.Numerics.Vectors
- Build successful after fixes
- Branch created: appmod/dotnet-migration-PlaintextCredential-to-SecureCredentials-20251102175521
