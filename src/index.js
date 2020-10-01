const NodeRtmpServer = require('./rtmp/node_rtmp_server');
const FfmpegEncode = require('./ffmpeg-encode');
const Hook = require('./hook');
const config = require('config');
const Logger = require('./logger');


const ffmpegSession = new Map();

// @todo: Check config require
const rtmpServer = new NodeRtmpServer();

rtmpServer.run();
/**
 * BIND FFMPEG on RTMP
 */
rtmpServer.on('postPublish', onPostPublish.bind(this));
rtmpServer.on('donePublish', onDonePublish.bind(this));
/**
 * BIND HOOK on RTMP
 */
rtmpServer.on('postPublish',Hook.onPublishRTMP);
rtmpServer.on('donePublish',Hook.onDoneRTMP);

/**
 *
 */
function onPostPublish(id, streamPath, args, publishStreamName,publishMetaData) {
    let session = new FfmpegEncode(
        `rtmp://127.0.0.1:${config.rtmp.port}${streamPath}`,
        streamPath,
        publishMetaData,
        args
        );
    ffmpegSession.set(id, session);
    session.on('end', () => {
        ffmpegSession.delete(id);
        rtmpServer.sessions.get(id)?.stop();
    });
    // Hook
    session.on('end', Hook.onDoneFFMPEG);
    try {
        session.run();
    }catch (e) {
        Logger.error(e);
        session.end();
        ffmpegSession.delete(id);
        rtmpServer.sessions.get(id)?.stop();
    }
}

function onDonePublish(id, streamPath, args,publishMetaData) {
    ffmpegSession.get(id)?.end();
}



