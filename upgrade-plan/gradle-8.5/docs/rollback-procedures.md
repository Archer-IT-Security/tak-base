# Gradle 8.5 Rollback Procedures

## Emergency Rollback

### Quick Rollback Steps
```bash
# 1. Restore Gradle wrapper version
./gradlew wrapper --gradle-version 7.5.1

# 2. Restore original Gradle files from backup
cp -r upgrade-plan/gradle-8.5/backups/original/* .

# 3. Clean Gradle caches
rm -rf ~/.gradle/caches/
```

## Planned Rollback

### 1. Pre-Rollback Checklist
- [ ] Notify all team members
- [ ] Stop all running builds
- [ ] Backup current state
- [ ] Document reason for rollback

### 2. Systematic Rollback Steps

#### a. Version Control
```bash
# Create rollback branch
git checkout -b rollback/gradle-7.5.1
```

#### b. Gradle Files
```bash
# Restore wrapper properties
cp upgrade-plan/gradle-8.5/backups/original/gradle/wrapper/gradle-wrapper.properties gradle/wrapper/

# Restore build scripts
cp upgrade-plan/gradle-8.5/backups/original/build.gradle .
cp upgrade-plan/gradle-8.5/backups/original/settings.gradle .
```

#### c. Plugin Versions
```groovy
// Restore original plugin versions
plugins {
    id 'com.google.protobuf' version '0.9.0'
    id 'com.github.johnrengelman.shadow' version '7.1.2'
}
```

### 3. Verification Steps

#### a. Basic Build
```bash
# Clean and test build
./gradlew clean build
```

#### b. Module Testing
```bash
# Test critical modules
./gradlew :takserver-protobuf:build
./gradlew :takserver-fig-core:build
./gradlew :federation-common:build
```

#### c. Integration Testing
```bash
# Run integration tests
./gradlew integrationTest
```

## Partial Rollback

### 1. Module-Specific Rollback
For rolling back specific problematic modules while keeping others on Gradle 8.5

```groovy
// settings.gradle
gradle.beforeProject { project ->
    if (project.name in ['problematic-module']) {
        project.gradle.gradleVersion = '7.5.1'
    }
}
```

### 2. Feature-Specific Rollback
For rolling back specific features while maintaining others

#### a. Configuration Cache
```groovy
// Disable only configuration cache
gradle.startParameter.configurationCache = false
```

#### b. Build Cache
```groovy
// Disable only build cache
buildCache {
    local {
        enabled = false
    }
}
```

## Post-Rollback Tasks

### 1. Verification
- [ ] All builds pass
- [ ] All tests pass
- [ ] CI/CD pipeline works
- [ ] Developer builds work

### 2. Documentation
- [ ] Update version control
- [ ] Update build documentation
- [ ] Notify team members
- [ ] Document rollback reason

### 3. Analysis
```markdown
## Rollback Analysis Report

### Reason for Rollback
[Document specific issues that triggered rollback]

### Impact Assessment
- Build System:
- Development Workflow:
- CI/CD Pipeline:
- Team Productivity:

### Lessons Learned
1. [Key learning points]
2. [What could be done differently]
3. [Prevention measures for future]

### Next Steps
1. [Plan for next upgrade attempt]
2. [Required fixes before next attempt]
3. [Timeline for next attempt]
```

## Recovery Plan

### 1. Short-term Recovery
- Fix immediate build issues
- Restore team productivity
- Document workarounds

### 2. Long-term Planning
- Analyze root causes
- Plan incremental updates
- Test in isolation

## Communication Template

```markdown
## Gradle Rollback Notification

### Status
- Previous Version: 8.5
- Rolled Back To: 7.5.1
- Date: [DATE]
- Time: [TIME]

### Impact
- Affected Projects: [LIST]
- Required Actions: [ACTIONS]
- Timeline: [TIMELINE]

### Next Steps
1. [STEP 1]
2. [STEP 2]
3. [STEP 3]

### Contact
- Technical Lead: [NAME]
- Build Engineer: [NAME]
```

## Monitoring Period

### 1. Build Metrics
- Track build times
- Monitor success rates
- Check resource usage

### 2. Developer Feedback
- Collect team feedback
- Document issues
- Track productivity impact

### 3. System Health
- Monitor CI/CD performance
- Check integration points
- Verify third-party tools

## Future Prevention

### 1. Testing Improvements
- Enhanced pre-upgrade testing
- Better integration tests
- Automated verification

### 2. Process Improvements
- Staged rollouts
- Better backup procedures
- Improved communication

### 3. Documentation Updates
- Clear procedures
- Better troubleshooting guides
- Updated requirements
