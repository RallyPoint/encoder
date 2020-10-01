const config = require('config');
const axios = require('axios');


async function authPublish(rtmpClient) {
    if(!config.authentification || !config.authentification.host || !config.authentification.uri){
        return {};
    }
    return await axios.post(`${config.get('authentification.host')}${config.get('authentification.uri')}`,{
        publishStreamName: rtmpClient.publishStreamName,
        ip: rtmpClient.ip
    }).then(function (res) {
            // handle success
            return res.data;
        }).catch(e => {
            throw new Error(JSON.stringify(e.response.data));
        });
}
//this.publishArgs.sign, this.publishStreamPath, this.config.auth.secret)


module.exports = {
    authPublish
};
