const axios = require('axios');
const cheerio = require('cheerio');

async function search() {
  const url = 'https://mychords.net/search?q=' + encodeURIComponent('Океан Ельзи');
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  const results = [];
  $('.b-listing__item').each((i, el) => {
    const title = $(el).find('.b-listing__item__title').text().trim();
    const link = $(el).find('a').attr('href');
    results.push({ title, link });
  });
  console.log(results);
}
search().catch(e => console.error(e.message));
