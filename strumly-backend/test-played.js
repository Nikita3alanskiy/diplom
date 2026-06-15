const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function test() {
  try {
    const user = await prisma.user.findFirst();
    const song = await prisma.song.findFirst();
    console.log(`User: ${user.id}, Song: ${song.id}`);
    
    const result = await prisma.playedSong.upsert({
      where: { userId_songId: { userId: user.id, songId: song.id } },
      create: { userId: user.id, songId: song.id },
      update: { playedAt: new Date() },
    });
    console.log(result);
  } catch (e) {
    console.error(e.message);
  } finally {
    await prisma.$disconnect();
  }
}
test();
