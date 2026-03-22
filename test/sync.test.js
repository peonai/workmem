#!/usr/bin/env node
import { execSync } from 'child_process';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { join } from 'path';
import { pathToFileURL } from 'url';

const testDir = join(process.cwd(), 'test-tmp');

function setup() {
  rmSync(testDir, { recursive: true, force: true });
  mkdirSync(testDir, { recursive: true });
  
  writeFileSync(join(testDir, 'package.json'), JSON.stringify({
    name: 'test-project',
    type: 'module',
    main: 'src/index.js'
  }));
  
  writeFileSync(join(testDir, 'README.md'), '# Test Project\n\nA test project for workmem sync.');
  
  mkdirSync(join(testDir, 'src'), { recursive: true });
  writeFileSync(join(testDir, 'src/index.js'), 'export function main() { console.log("hello"); }');
  
  execSync('git init -q', { cwd: testDir });
  
  execSync(`node ${join(process.cwd(), 'bin/workmem.js')} init --backend claude "${testDir}"`, { 
    cwd: testDir,
    stdio: 'ignore'
  });
  
  const memoryRoot = join(testDir, '.agent', 'memory');
  writeFileSync(join(memoryRoot, 'episodic', '2026-03-22.md'), `# 2026-03-22

## Work Log
- Implemented main function
- Added basic logging

## Findings
- Project uses ESM modules
- Entry point is src/index.js

## Follow-ups
- Add error handling
- Write tests
`);
}

function cleanup() {
  rmSync(testDir, { recursive: true, force: true });
}

async function runTest() {
  console.log('Setting up test environment...');
  setup();
  
  try {
    const syncPath = join(testDir, '.claude/plugins/workmem/scripts/memory/sync.js');
    const syncModule = await import(pathToFileURL(syncPath).href);
    
    console.log('Running sync.js...');
    const result = await syncModule.runCli({ cwd: testDir, silent: true });
    
    if (!result.stdout) throw new Error('No output from sync');
    
    const output = JSON.parse(result.stdout);
    
    if (output.extractionMode !== 'heuristic') {
      throw new Error(`Expected heuristic mode, got ${output.extractionMode}`);
    }
    
    if (!output.projectPath || !output.activePath) {
      throw new Error('Missing required output paths');
    }
    
    console.log('✓ sync.js executed successfully');
    console.log(`✓ extractionMode: ${output.extractionMode}`);
    console.log('✓ All tests passed');
    
  } finally {
    cleanup();
  }
}

runTest().catch((error) => {
  console.error('✗ Test failed:', error.message);
  cleanup();
  process.exit(1);
});
