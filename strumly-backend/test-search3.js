const axios = require('axios');
const cheerio = require('cheerio');

async function search() {
  const url = 'https://mychords.net/search?q=' + encodeURIComponent('Океан Ельзи');
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  console.log($('.b-result__list').html() ? 'has b-result__list' : 'no b-result__list');
  console.log($('.gsc-result').html() ? 'has gsc-result' : 'no gsc-result');
  console.log($('ul.b-listing').html() ? 'has ul.b-listing' : 'no ul.b-listing');
  console.log($('.b-search').html() ? 'has b-search' : 'no b-search');
}
search().catch(e => console.error(e.message));
