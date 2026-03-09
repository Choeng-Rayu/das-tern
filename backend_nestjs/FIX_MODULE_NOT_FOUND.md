# DasTern Backend - Module Not Found Fix

## Problem
When running `npm run start:dev` or `npm run start:prod`, you get:
```
Error: Cannot find module '/home/rayu/das-tern/backend_nestjs/dist/main'
```

This happens because the `dist/main.js` file is not being generated during the build process.

## Root Cause
The NestJS build system (`nest build` command) is not producing the JavaScript output file, likely due to:
1. TypeScript compilation configuration issues
2. Nest CLI cache issues
3. Incremental build problems

## Solutions

### Solution 1: Use ts-node for Development (RECOMMENDED)
The easiest way to run the backend without dealing with build issues:

```bash
cd /home/rayu/das-tern/backend_nestjs
chmod +x run-backend-dev.sh
./run-backend-dev.sh
```

This uses `ts-node` to execute TypeScript directly without compilation, perfect for development.

**Advantages:**
- No build step needed
- Fast startup
- Live reload with 'npm run start:dev' script
- Ideal for development

### Solution 2: Manual TypeScript Compilation
If you need a production-ready compiled version:

```bash
cd /home/rayu/das-tern/backend_nestjs
chmod +x run-backend-simple.sh
./run-backend-simple.sh
```

This script:
1. Clears the dist folder
2. Clears TypeScript build cache
3. Compiles TypeScript to JavaScript
4. Starts the application

### Solution 3: Fix npm Scripts
Update your npm scripts in `package.json`:

```json
{
  "scripts": {
    "start": "ts-node -r tsconfig-paths/register src/main.ts",
    "start:dev": "ts-node -r tsconfig-paths/register --watch src/main.ts",
    "start:prod": "node dist/main",
    "build": "tsc --listFiles false"
  }
}
```

Then:
```bash
npm run start:dev
```

### Solution 4: Fix NestJS Build Configuration
Make sure `nest-cli.json` uses the correct TypeScript config:

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true,
    "webpack": false,
    "tsConfigPath": "tsconfig.build.json"
  }
}
```

Then try:
```bash
npm run build
npm run start:prod
```

## Verification Steps

### Check if dist/main.js exists:
```bash
ls -la /home/rayu/das-tern/backend_nestjs/dist/main.js
```

### Check if dist folder was created:
```bash
ls -la /home/rayu/das-tern/backend_nestjs/dist/ | head -20
```

### Run backend with debugging:
```bash
cd /home/rayu/das-tern/backend_nestjs
npm install
npm run start:dev
```

## Expected Output
When successful, you should see:
```
🚀 Application is running on: http://localhost:3000/api/v1
```

## Troubleshooting

If you still get "Cannot find module" error:

1. **Clear all caches:**
   ```bash
   rm -rf node_modules dist
   rm -f tsconfig*.tsbuildinfo
   npm install
   ```

2. **Try ts-node directly:**
   ```bash
   cd backend_nestjs
   npx ts-node -r tsconfig-paths/register src/main.ts
   ```

3. **Check Node.js version:**
   ```bash
   node --version  # Should be v18+ for best compatibility
   npm --version
   ```

4. **Verify TypeScript is installed:**
   ```bash
   npx tsc --version
   ```

## Notes
- Development mode with `ts-node` is recommended during development
- For production, compile with `npm run build` then run `npm run start:prod`
- If decorator errors appear, ensure `tsconfig.json` has:
  - `"experimentalDecorators": true`
  - `"emitDecoratorMetadata": true`
