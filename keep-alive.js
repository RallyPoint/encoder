const config = require('config');
const  axios = require('axios');
const xml2json = require('xml2json');

keepAlive();

setInterval(keepAlive, config.get('INTERVAL_KEEP_ALIVE'));

async function keepAlive() {
    const resStats = await axios.get(config.get('STATS_URL'));
    console.log(config.get('LB_DNS_URL'),xml2json.toJson(resStats.data));
    //axios.post(config.get('LB_DNS_URL'),xml2json.toJson(resStats.data));
}
