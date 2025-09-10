# Migration Progress: Local SQL Server to Azure SQL MI Instance

## Important Guidelines
1. When using terminal commands, never input a long command with multiple lines, always use a single line command. (This is a bug in VS Copilot)
2. Never create a new project in the solution, always use the existing project to add new files or update the existing files.
3. Minimize code changes:
   - Update only what's necessary for the migration.
   - Avoid unrelated code enhancement.

## Migration Tasks

### Phase 1: Package Dependencies Update
- [X] Backup current packages.config and .csproj files
- [X] Update Microsoft.Data.SqlClient to version 6.1.1 in packages.config (found newer version already in PackageReference)
- [X] Add Azure.Identity version 1.14.0 to packages.config and PackageReference
- [X] Update .csproj file to reference new packages
- [X] Remove old System.Data.SqlClient package references from legacy section
- [in_progress] Restore NuGet packages and verify no conflicts

### Phase 2: Version Control Setup
- [X] Check git status and stash any uncommitted changes (excluding .appmod/)
- [X] Get current timestamp in format yyyyMMddHHmmss: 20250910195320
- [X] Create new branch: appmod/dotnet-migration-local-sql-server-to-Azure-SQL-MI-instance-20250910195320
- [X] Commit initial migration plan and progress files

### Phase 3: Code Updates
- [ ] Update using statements in Data/SchoolContext.cs
- [ ] Search for any System.Data.SqlClient usages in the entire project
- [ ] Replace System.Data.SqlClient with Microsoft.Data.SqlClient in all files
- [ ] Update any Microsoft.SqlServer.Server references to Microsoft.Data.SqlClient.Server
- [ ] Verify all SQL-related code compiles

### Phase 4: Entity Framework Configuration
- [ ] Review Entity Framework provider configuration
- [ ] Update any EF-specific configurations for Microsoft.Data.SqlClient
- [ ] Add provider factory registration if needed in Global.asax.cs
- [ ] Test Entity Framework context instantiation

### Phase 5: Connection String Migration
- [ ] Backup original Web.config
- [ ] Update connection string in Web.config to Azure SQL MI format
- [ ] Replace LocalDB connection with: Server=tcp:<managed-instance-name>.<dns-zone>.database.windows.net,3342;Database=ContosoUniversityNoAuthEFCore;Authentication=Active Directory Default;TrustServerCertificate=True;MultipleActiveResultSets=True
- [ ] Add configuration for multiple environments if needed
- [ ] Verify connection string format is correct

### Phase 6: Security and Authentication
- [ ] Configure application for Azure Managed Identity
- [ ] Remove any hardcoded credentials
- [ ] Test Managed Identity authentication configuration
- [ ] Verify secure connection setup

### Phase 7: Build and Verification
- [ ] Build the solution and fix any compilation errors
- [ ] Verify all projects load correctly
- [ ] Run basic application startup test
- [ ] Verify Entity Framework migrations work
- [ ] Test database connectivity (if Azure SQL MI is available)

### Phase 8: CVE Vulnerability Check
- [ ] Collect all newly added packages and versions
- [ ] Run CVE vulnerability check on new packages
- [ ] Update package versions if vulnerabilities found
- [ ] Document CVE check results

### Phase 9: Final Review and Documentation
- [ ] Review all changes made during migration
- [ ] Verify all tasks are completed
- [ ] Commit final changes with descriptive message
- [ ] Update documentation with migration notes
- [ ] Create summary of changes for stakeholders

## Current Status: Starting Migration Execution
**Next Action**: Phase 2 - Version Control Setup
**Timestamp**: 20250910195320

## Notes and Issues
- Azure SQL MI instance details needed for connection string
- Managed Identity configuration may require Azure environment setup
- Database migration (schema/data) handled separately from application migration

## Completed Tasks
None yet - waiting for user confirmation to proceed.

---
**Last Updated**: Migration plan created, ready to start execution.