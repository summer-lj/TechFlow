export default {
  'apps/api/{src,test}/**/*.ts': ['prettier --write', 'eslint --fix'],
  '**/*.{js,mjs,cjs}': ['prettier --write'],
  '**/*.{json,md,yml,yaml}': ['prettier --write'],
};
