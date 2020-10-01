const config = require('config');
const axios = require('axios');
const Logger = require('./logger');


function isSetted(hookName){
    return config.hooks &&
        config.hooks.enable &&
        config.hooks.host &&
        config.hooks[hookName];
}

async function callHook(hookName,data){
    if(!isSetted(hookName)) { return {}; }
    console.log(hookName);
    return await axios.post(
        `${config.hooks.host}${config.hooks[hookName]}`,
        data
    ).then(function (res) {
        Logger.log("[hook] Hook Success for", hookName);
        return res.data;
    }).catch(e => {
        Logger.error("[hook] Hook fail for", hookName, JSON.stringify(data));
        return null;
    });
}

async function onPublishRTMP(id, streamPath, args, publishStreamName,publishMetaData) {
    return await callHook('onPublish',{
        publishStreamName,
        publishMetaData
    });
}
async function onDoneRTMP(id, streamPath, args, publishStreamName,publishMetaData) {
    return await callHook('onDone',{
        publishStreamName,
        publishMetaData
    });
}
async function onDoneFFMPEG(publishMetaData,recordFile) {
    return await callHook('onRecordDone',{
        publishMetaData,
        recordFile
    });
}
module.exports = {
    onPublishRTMP,
    onDoneRTMP,
    onDoneFFMPEG
};
