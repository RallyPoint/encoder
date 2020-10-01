//
//  Created by Mingliang Chen on 18/3/9.
//  illuspas[a]gmail.com
//  Copyright (c) 2018 Nodemedia. All rights reserved.
//
const Logger = require('./logger');


const EventEmitter = require('events');
const { spawn } = require('child_process');
const dateFormat = require('dateformat');
const mkdirp = require('mkdirp');
const fs = require('fs');
const config = require('config');

const defaulConf = {
  vc : "copy",
  ac : "copy"
};

class FfmpegEncode extends EventEmitter {
  constructor(inPath, outPath, publishMetaData,publishArgs) {
    super();
    this.publishArgs = publishArgs || {};
    this.recordFile = null;
    this.publishMetaData = publishMetaData;
    this.inPath = inPath;
    this.fluxPath = outPath;
    this.ouPath = config.mediaroot + outPath;
  }

  run() {
    let mapStr = '';
    // Record

    if(config.twitch && config.twitch.enable && this.publishMetaData && this.publishArgs.twitch){
      mapStr += `[f=flv]${config.twitch.host}${this.publishArgs.twitch}|`;
    }
    if (config.record?.enable) {
      this.recordFile = dateFormat('yyyy-mm-dd-HH-MM-ss') + '.mp4';
      const path = config.record.outPath ? config.record.outPath+this.fluxPath :this.ouPath;
      mkdirp.sync(path);
      mapStr += `${config.record?.flags || ""}${path}${this.recordFile}|`;
      Logger.log('[Transmuxing MP4] ' + this.inPath + ' to ' + this.ouPath + '/' + this.recordFile);
    }
    // HLS
    if (config.hls?.enable) {
      // @todo : Utile ?
      let hlsFileName = 'index.m3u8';
      mapStr += `${config.hls?.flags || ""}${this.ouPath}${hlsFileName}|`;
      Logger.log('[Transmuxing HLS] ' + this.inPath + ' to ' + this.ouPath + '/' + hlsFileName);
    }
    // DASh
    /*
    if (config.dash?.enable) {
      this.conf.dashFlags = this.conf.dashFlags ? this.conf.dashFlags : '';
      let dashFileName = 'index.mpd';
      let mapDash = `${this.conf.dashFlags}${this.ouPath}/${dashFileName}`;
      mapStr += mapDash;
      Logger.log('[Transmuxing DASH] ' + this.inPath + ' to ' + this.ouPath + '/' + dashFileName);
    }
     */

    try {
      mkdirp.sync(this.ouPath);
    }catch (e) {
      Logger.error("[Ffmpeg-encode]Can create outPath")
    }
    let argv = ['-y', '-i', this.inPath,'-map','0:v?','-map','0:a?','-flags','+global_header','-vsync','1','-async','1'];
    Array.prototype.push.apply(argv, ['-c:v', config.ffmpeg.vc]);
    Array.prototype.push.apply(argv, config.ffmpeg.vcParam);
    Array.prototype.push.apply(argv, ['-c:a', config.ffmpeg.ac]);
    Array.prototype.push.apply(argv, config.ffmpeg.acParam);
    Array.prototype.push.apply(argv, ['-f', 'tee', mapStr]);
    if(config.thumbnail && config.thumbnail.enable){
      const path = config.thumbnail.outPath ? config.thumbnail.outPath+this.fluxPath :this.ouPath;
      mkdirp.sync(path);
      Array.prototype.push.apply(argv, ['-map', '0:v?','-vf:v', `fps=${config.thumbnail.fps}`, '-update', '1', `${path}thumbnail.jpg`]);
//        mapStr += `[select='v':update=1:f=image2:vsync=crf]${path}thumbnail.jpg|`
    }

    argv = argv.filter((n) => { return n }); //去空
    this.ffmpeg_exec = spawn(config.ffmpeg.path, argv);
    this.ffmpeg_exec.on('error', (e) => {
      Logger.ffdebug(e);
    });

    this.ffmpeg_exec.stdout.on('data', (data) => {
      Logger.ffdebug(`FF data：${data}`);
    });

    this.ffmpeg_exec.stderr.on('data', (data) => {
      Logger.ffdebug(`FF data：${data}`);
    });

    this.ffmpeg_exec.on('close', (code) => {
      Logger.log('[Transmuxing end] ' + this.inPath);
      this.emit('end', this.publishMetaData, this.recordFile);
      fs.readdir(this.ouPath, function (err, files) {
        if (!err) {
          files.forEach((filename) => {
            if (filename.endsWith('.ts')
              || filename.endsWith('.m3u8')
              || filename.endsWith('.mpd')
              || filename.endsWith('.m4s')
              || filename.endsWith('.tmp')) {
              try {
                fs.unlinkSync(this.ouPath + '/' + filename);
              }catch (e) {
                
              }
            }
          })
        }
      });
    });
  }

  end() {
    this.ffmpeg_exec.kill();
  }
}

module.exports = FfmpegEncode;
