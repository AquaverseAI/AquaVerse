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
  
  // Verify key FastAPI route contracts exist in the generated TypeScript SDK.
  const requiredPaths = [
    '/v1/auth/otp/request',
    '/v1/auth/otp/verify',
    '/v1/auth/token',
    '/v1/media/upload-url',
    '/v1/media/{media_id}/commit',
    '/v1/ponds/{pond_id}/forecast/do',
    '/v1/ask',
    '/v1/reports/export/{job_id}',
  ];

  let missing = [];
  for (const route of requiredPaths) {
    if (!content.includes(route)) {
      missing.push(route);
    }
  }

  if (missing.length > 0) {
    console.error(`❌ Contract test failed: Missing routes in generated SDK: ${missing.join(', ')}`);
    process.exit(1);
  }

  const stalePaths = ['/v1/media/presign', '/v1/media/commit', '/v1/forecast/temporal'];
  const stale = stalePaths.filter((route) => content.includes(route));
  if (stale.length) {
    console.error(`❌ Contract test failed: Stale routes remain: ${stale.join(', ')}`);
    process.exit(1);
  }

  console.log('✅ Contract test passed: generated SDK matches required FastAPI routes.');
}

testContract();
