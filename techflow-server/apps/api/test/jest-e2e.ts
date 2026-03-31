import type { Config } from 'jest';

const config: Config = {
  rootDir: '..',
  moduleFileExtensions: ['js', 'json', 'ts'],
  testRegex: '.*\\.e2e-spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': [
      'ts-jest',
      {
        tsconfig: './tsconfig.json',
      },
    ],
  },
  testEnvironment: 'node',
  coverageDirectory: '../../coverage/api/e2e',
  detectOpenHandles: true,
  maxWorkers: 1,
};

export default config;
