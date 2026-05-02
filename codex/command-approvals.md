# Codex command approval reference

Codex approval state is stored in local runtime files under `~/.codex` and
should not be copied between laptops. Use this as the reference list when a new
machine asks whether recurring commands should be allowed.

Prefer scoped prefixes rather than broad shells or arbitrary interpreters.

## Build and development

- `npm.cmd run`
- `npm.cmd install`
- `npm.cmd run build`
- `Start-Process -FilePath npm.cmd`

## Git and GitHub

- `git add`
- `git commit -m`
- `git switch -c`
- `git clone https://github.com/`
- `git push origin` covers branch-specific pushes such as `git push origin master` and `git push origin ux-refactor`
- `git push -u origin`
- `git ls-remote --heads origin`
- `gh repo view`
- `gh pr view`
- `gh pr list`
- `gh pr create`

## Akka and Windows inspection

- `akka specify init .`
- `akka mcp serve`
- `Get-CimInstance Win32_Process`

Do not approve broad prefixes such as `powershell`, `python`, `python -`,
`cmd`, `bash`, or destructive filesystem commands.
