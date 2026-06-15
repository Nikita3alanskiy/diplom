const axios = require('axios');
const cheerio = require('cheerio');

async function search() {
  const url = 'https://amdm.ru/search/?q=' + encodeURIComponent('Океан Ельзи');
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  const items = [];
  $('table.items tr').each((i, el) => {
    const links = $(el).find('a.artist');
    if (links.length >= 2) {
      const artist = $(links[0]).text().trim();
      const songTitle = $(links[1]).text().trim();
      const songUrl = $(links[1]).attr('href');
      items.push({ title: `${artist} - ${songTitle}`, url: songUrl });
    }
  });
  console.log(items.slice(0, 5));
}
search().catch(e => console.error(e.message));
