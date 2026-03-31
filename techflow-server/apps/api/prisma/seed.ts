import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const email = (process.env.DEFAULT_ADMIN_EMAIL ?? 'founder@example.com').toLowerCase();
  const name = process.env.DEFAULT_ADMIN_NAME ?? 'Founder Admin';
  const password = process.env.DEFAULT_ADMIN_PASSWORD ?? 'ChangeMe123!';
  const passwordHash = await bcrypt.hash(password, 10);

  await prisma.user.upsert({
    where: { email },
    update: {
      name,
      passwordHash,
      role: Role.ADMIN,
      isActive: true,
    },
    create: {
      email,
      name,
      passwordHash,
      role: Role.ADMIN,
      isActive: true,
    },
  });
}

main()
  .catch((error) => {
    console.error('Seed failed', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
