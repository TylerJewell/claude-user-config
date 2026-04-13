# fe-build — Angular Frontend Build

Builds the Angular frontend and copies compiled assets to the Java static resources directory. Use this whenever frontend source files have been edited and need to be served by the Akka backend.

## Usage
- `/fe-build` or `/fe-build dev` — development build (fast, source maps, no optimization)
- `/fe-build prod` — production build (optimized, for deployment)
- `/fe-build serve` — start ng serve dev server on port 4200 with proxy

## Steps

### dev (default)
1. Run: `cd compliance-surface/frontend && npx ng build --configuration development`
2. If compilation fails: report the TypeScript/template error lines exactly, stop here
3. If success: `cp -r dist/frontend/browser/* ../src/main/resources/static-resources/`
4. Copy built files: `cp -r dist/frontend/browser/* ../src/main/resources/static-resources/`
5. ALWAYS restart the Akka service using `akka_local_run_service` — Akka serves static files
   from `target/classes/` (compiled classpath), not `src/main/resources/` directly. The copy
   in step 4 only takes effect after recompile+restart. Use the MCP tool, not raw mvn.

### prod
1. Run: `cd compliance-surface/frontend && npx ng build`
2. If compilation fails: report errors, stop
3. Copy: `cp -r dist/frontend/browser/* ../src/main/resources/static-resources/`
4. Report bundle sizes from ng build output

### serve
1. Check if ng serve is already running on port 4200: `netstat -an | grep 4200`
2. If already running: report it and stop (don't start a second instance)
3. If not running: `cd compliance-surface/frontend && npx ng serve --configuration development --port 4200`
4. Remind user: port 4200 (ng serve) has SEPARATE localStorage from port 9002 (Akka static)
   - Zoom preferences, theme settings stored at one port won't appear at the other
   - Use this difference as a diagnostic tool when debugging layout issues

## Key paths
- Source: `compliance-surface/frontend/src/`
- Build output: `compliance-surface/frontend/dist/frontend/browser/`
- Static resources: `compliance-surface/src/main/resources/static-resources/`

## Common issues
- **ng serve misses file changes on Windows**: the watcher sometimes doesn't pick up edits
  from external tools. Kill the process (`netstat -ano | findstr :4200` then `taskkill /PID <pid> /F`) and restart.
- **Stale UI after build**: hard refresh in browser (Ctrl+Shift+R) to bypass cache
- **TypeScript error after adding a new component**: check that it's listed in the route's
  `loadComponent` import and that the selector matches exactly
