const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const songs = await prisma.song.findMany();
  for (const song of songs) {
    if (song.audioUrl && song.audioUrl.includes('10.0.2.2')) {
      const newUrl = song.audioUrl.replace('10.0.2.2', '192.168.250.105');
      await prisma.song.update({
        where: { id: song.id },
        data: { audioUrl: newUrl }
      });
      console.log(`Updated song ${song.id}`);
    }
  }
}
main().then(() => prisma.$disconnect());
