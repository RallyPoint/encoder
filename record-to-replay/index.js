const mysql      = require('mysql');
const config     = require('config');
const ffmpeg = require('fluent-ffmpeg');
const uuidGen = require('uuid');
const connection = mysql.createConnection({
    host     : config.get('mysql.host'),
    user     : config.get('mysql.username'),
    password : config.get('mysql.password'),
    database : config.get('mysql.database'),
    port     : config.get('mysql.port')
});
const uuid = uuidGen.v4();
const START_DELAY = Math.floor(Math.random() * 5000);
connection.connect();

const query = (req)=>{
    return new Promise((resolve, reject) => {
        connection.query(req, (error, results, fields) => {
            if (error) reject(error);
            resolve(results,fields);
        });
    });
};

const run = async () => {
    // Delay for concurent convertion if you are scaling
    await new Promise((resolve,reject)=>setTimeout(resolve,START_DELAY));
    // Reserve one record
    await query('UPDATE replay_entity SET convertId = "'+uuid+'" WHERE status = false AND convertId IS null LIMIT 1');
    // Get record reserved
    const results = await query('SELECT * FROM replay_entity WHERE convertId = "'+uuid+'" AND status = false;');

    if (!results.length) return;
    const result = results[0];
    return new Promise((resolve, reject)=>{
        let duration = 0;
        const fileName = result.path.split('/').slice(-1)[0].split('.').slice(0,-1).join('.');
        console.log(result.path.split('/').slice(-1),fileName);
        try {
            ffmpeg.ffprobe(result.path, function(err, data) {
                duration= data.format.duration;
                console.log(seek);

                ffmpeg(result.path)

                    .videoCodec('copy')
                    .format('mp4')
                    .output(config.get('convert.outputPath')+fileName+'.mp4')

                    .on('end', function() {
                        console.log('Finished processing');
                        query('UPDATE replay_entity SET status = true, duration = "'+duration+'" WHERE id = "'+result.id+'"').then(resolve).catch(reject);
                    })
                    .on('error', function (error) {
                        reject(error);
                    })
                    .run();

            });
        }catch (e) {
            reject(e);
        }
    })


};

run().catch((e)=>{
    console.error(e);
}).then(()=>{
    connection.end();
});
