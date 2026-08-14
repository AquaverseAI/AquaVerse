import openapiTS, { astToString } from 'openapi-typescript';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function generateSDK() {
  console.log('Generating typed SDK from openapi.yaml...');
  const openapiPath = path.resolve(__dirname, '../openapi.yaml');
  const outputPath = path.resolve(__dirname, '../src/api/generated-sdk.ts');

  if (!fs.existsSync(openapiPath)) {
    console.error(`openapi.yaml not found at ${openapiPath}`);
    process.exit(1);
  }

  const ast = await openapiTS(new URL(`file://${openapiPath}`));
  const contents = astToString(ast);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, contents);
  console.log(`✅ Typed SDK successfully generated at ${outputPath}`);
}

generateSDK().catch((err) => {
  console.error('Failed to generate SDK:', err);
  process.exit(1);
});
