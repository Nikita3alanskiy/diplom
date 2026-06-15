const axios = require('axios');
const cheerio = require('cheerio');

async function scrape() {
  const url = 'https://amdm.ru/akkordi/skryabin/99723/spichki/';
  const { data } = await axios.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });
  const $ = cheerio.load(data);
  const text = $('pre[itemprop="text"]').text();
  console.log('Text preview:', text.substring(0, 100));
  
  const ytIframe = $('iframe[src*="youtube.com"]').attr('src');
  console.log('YouTube iframe:', ytIframe);
}
scrape().catch(console.error);
