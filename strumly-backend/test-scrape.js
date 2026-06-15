const axios = require('axios');
const cheerio = require('cheerio');

async function scrape() {
  const url = 'https://mychords.net/';
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  const title = $('title').text();
  console.log('Title:', title);
}
scrape().catch(e => console.error(e.message));
