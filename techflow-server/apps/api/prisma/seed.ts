import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const normalizePhone = (value: string) => value.replace(/\D/g, '');

async function main() {
  const phone = normalizePhone(process.env.DEFAULT_ADMIN_PHONE ?? '13965026764');
  const email = (process.env.DEFAULT_ADMIN_EMAIL ?? `${phone}@techflow.local`).toLowerCase();
  const name = process.env.DEFAULT_ADMIN_NAME ?? 'Founder Admin';
  const password = process.env.DEFAULT_ADMIN_PASSWORD ?? '123456';
  const passwordHash = await bcrypt.hash(password, 10);
  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ phone }, { email }],
    },
  });

  if (existingUser) {
    await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        email,
        phone,
        name,
        passwordHash,
        role: Role.ADMIN,
        isActive: true,
      },
    });

    return;
  }

  await prisma.user.create({
    data: {
      email,
      phone,
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
