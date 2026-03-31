import * as Joi from 'joi';

interface EnvironmentVariables {
  NODE_ENV: string;
  APP_NAME: string;
  APP_HOST: string;
  PORT: number;
  API_PREFIX: string;
  LOG_LEVEL: string;
  TRUST_PROXY: boolean;
  SWAGGER_ENABLED: boolean;
  CORS_ORIGINS: string;
  DATABASE_HOST: string;
  DATABASE_PORT: number;
  DATABASE_NAME: string;
  DATABASE_USER: string;
  DATABASE_PASSWORD: string;
  DATABASE_URL: string;
  REDIS_HOST: string;
  REDIS_PORT: number;
  REDIS_URL: string;
  JWT_ACCESS_SECRET: string;
  JWT_ACCESS_TTL: string;
  JWT_REFRESH_SECRET: string;
  JWT_REFRESH_TTL: string;
  DEFAULT_ADMIN_EMAIL: string;
  DEFAULT_ADMIN_PHONE: string;
  DEFAULT_ADMIN_PASSWORD: string;
  DEFAULT_ADMIN_NAME: string;
  AUTO_MIGRATE: boolean;
  AUTO_SEED: boolean;
}

export function validateEnv(config: Record<string, unknown>) {
  const schema = Joi.object<EnvironmentVariables>({
    NODE_ENV: Joi.string()
      .valid('development', 'test', 'staging', 'production')
      .default('development'),
    APP_NAME: Joi.string().default('backend-starter'),
    APP_HOST: Joi.string().default('0.0.0.0'),
    PORT: Joi.number().port().default(3000),
    API_PREFIX: Joi.string().default('api/v1'),
    LOG_LEVEL: Joi.string().default('info'),
    TRUST_PROXY: Joi.boolean().truthy('true').falsy('false').default(false),
    SWAGGER_ENABLED: Joi.boolean().truthy('true').falsy('false').default(true),
    CORS_ORIGINS: Joi.string().allow('').default(''),
    DATABASE_HOST: Joi.string().default('postgres'),
    DATABASE_PORT: Joi.number().port().default(5432),
    DATABASE_NAME: Joi.string().default('backend_local'),
    DATABASE_USER: Joi.string().default('backend'),
    DATABASE_PASSWORD: Joi.string().default('backend'),
    DATABASE_URL: Joi.string()
      .uri({ scheme: ['postgresql', 'postgres'] })
      .required(),
    REDIS_HOST: Joi.string().default('redis'),
    REDIS_PORT: Joi.number().port().default(6379),
    REDIS_URL: Joi.string()
      .uri({ scheme: ['redis'] })
      .required(),
    JWT_ACCESS_SECRET: Joi.string().min(12).required(),
    JWT_ACCESS_TTL: Joi.string().default('15m'),
    JWT_REFRESH_SECRET: Joi.string().min(12).required(),
    JWT_REFRESH_TTL: Joi.string().default('7d'),
    DEFAULT_ADMIN_EMAIL: Joi.string().email().required(),
    DEFAULT_ADMIN_PHONE: Joi.string()
      .pattern(/^1\d{10}$/)
      .default('13965026764'),
    DEFAULT_ADMIN_PASSWORD: Joi.string().min(6).required(),
    DEFAULT_ADMIN_NAME: Joi.string().required(),
    AUTO_MIGRATE: Joi.boolean().truthy('true').falsy('false').default(false),
    AUTO_SEED: Joi.boolean().truthy('true').falsy('false').default(false),
  });

  const validationResult = schema.validate(config, {
    abortEarly: false,
    allowUnknown: true,
  });
  const error = validationResult.error;
  // Joi does not preserve a concrete return type here, so we narrow after validation succeeds.
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const value: EnvironmentVariables = validationResult.value;

  if (error) {
    throw new Error(`Environment validation failed: ${error.message}`);
  }

  return value;
}
