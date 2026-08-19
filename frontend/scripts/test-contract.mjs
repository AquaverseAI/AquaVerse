import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function testContract() {
  console.log('Running contract tests against generated SDK...');
  const sdkPath = path.resolve(__dirname, '../src/api/generated-sdk.ts');
  
  if (!fs.existsSync(sdkPath)) {
    console.error('❌ Contract test failed: Generated SDK file missing. Run `npm run gen-sdk` first.');
    process.exit(1);
  }

  const content = fs.readFileSync(sdkPath, 'utf8');
  
  // Verify key schema contracts exist in generated TypeScript SDK
  const requiredSchemas = [
    'PondRecord',
    'PondEvent',
    'ExplanationPayload',
    'TriageItem',
    'DOForecast',
    'TwinState',
    'AlertItem',
    'AdvisoryItem'
  ];

  let missing = [];
  for (const schema of requiredSchemas) {
    if (!content.includes(schema)) {
      missing.push(schema);
    }
  }

  if (missing.length > 0) {
    console.error(`❌ Contract test failed: Missing schemas in generated SDK: ${missing.join(', ')}`);
    process.exit(1);
  }

  console.log('✅ Contract test passed: All OpenAPI schemas verified in generated TypeScript SDK.');
}

testContract();
