@echo off
setlocal
echo Running git operations...
git add .github\workflows\selfservice-azure-infrastructure-onboarding.yaml
ngit commit -m "fix(workflow): correct YAML for selfservice onboarding" || echo no changes to commit
ngit push
endlocal
