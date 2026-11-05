const admin = require('firebase-admin');

const fs = require('fs');

const path = require('path');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({

  credential: admin.credential.cert(serviceAccount),

  storageBucket: 'the-oman-tourist-mate-27766.firebasestorage.app',

});

const bucket = admin.storage().bucket();

const assetsDir = path.resolve(__dirname, '..', 'assets');

const extensions = [

  '.mp3',

  '.wav',

  '.m4a',

  '.aac',

  '.ogg',

];

function getContentType(ext) {

  const types = {

    '.mp3': 'audio/mpeg',

    '.wav': 'audio/wav',

    '.m4a': 'audio/mp4',

    '.aac': 'audio/aac',

    '.ogg': 'audio/ogg',

  };

  return types[ext] || 'application/octet-stream';

}

async function getAudioFiles(dir) {

  const results = [];

  const entries = await fs.promises.readdir(dir, {

    withFileTypes: true,

  });

  for (const entry of entries) {

    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {

      results.push(...await getAudioFiles(fullPath));

    } else if (

      extensions.includes(path.extname(entry.name).toLowerCase())

    ) {

      results.push(fullPath);

    }

  }

  return results;

}

async function main() {

  console.log('Firebase bucket:', bucket.name);

  console.log('Scanning audio files...');

  const files = await getAudioFiles(assetsDir);

  console.log('Found:', files.length, 'audio files');

  let uploaded = 0;

  let skipped = 0;

  let failed = 0;

  let nextIndex = 0;

  async function worker() {

    while (nextIndex < files.length) {

      const filePath = files[nextIndex++];

      const relativePath = path.relative(

        assetsDir,

        filePath

      ).split(path.sep).join('/');

      const destination = `audio/${relativePath}`;

      try {

        const remoteFile = bucket.file(destination);

        const [exists] = await remoteFile.exists();

        if (exists) {

          skipped++;

          continue;

        }

        const ext = path.extname(filePath).toLowerCase();

        await bucket.upload(filePath, {

          destination,

          resumable: true,

          metadata: {

            contentType: getContentType(ext),

          },

        });

        uploaded++;

        console.log(

          `[${uploaded + skipped}/${files.length}] Uploaded:`,

          relativePath

        );

      } catch (error) {

        failed++;

        console.error('Failed:', relativePath, error.message);

      }

    }

  }

  await Promise.all([

    worker(),

    worker(),

  ]);

  console.log('\n========== RESULTS ==========');

  console.log('Total:', files.length);

  console.log('Uploaded:', uploaded);

  console.log('Skipped:', skipped);

  console.log('Failed:', failed);

  console.log('=============================');

}

main().catch(console.error);
 