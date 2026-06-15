const axios = require('axios');
const cheerio = require('cheerio');

async function search() {
  const url = 'https://mychords.net/search?q=' + encodeURIComponent('Океан Ельзи');
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  const items = [];
  $('a').each((i, el) => {
    const link = $(el).attr('href');
    const text = $(el).text().trim();
    if (link && link.includes('.html') && text.length > 5) {
      items.push({ text, link });
    }
  });
  console.log(items.slice(0, 5));
}
search().catch(e => console.error(e.message));
