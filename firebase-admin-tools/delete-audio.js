const admin = require('firebase-admin');

const path = require('path');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({

  credential: admin.credential.cert(serviceAccount),

  storageBucket: 'the-oman-tourist-mate-27766.firebasestorage.app',

});

const bucket = admin.storage().bucket();

const extensions = [

  '.mp3',

  '.wav',

  '.m4a',

  '.aac',

  '.ogg',

];

async function main() {

  console.log('Scanning Firebase Storage...');

  const [files] = await bucket.getFiles({

    prefix: 'audio/',

  });

  const audioFiles = files.filter(file =>

    extensions.includes(

      path.posix.extname(file.name).toLowerCase()

    )

  );

  console.log('Audio files found:', audioFiles.length);

  if (process.argv.includes('--delete')) {

    let deleted = 0;

    for (const file of audioFiles) {

      await file.delete();

      deleted++;

      console.log('Deleted:', file.name);

    }

    console.log('======================');

    console.log('Deleted:', deleted);

    console.log('======================');

  } else {

    console.log('\nDRY RUN - Nothing deleted.');

    audioFiles.forEach(file =>

      console.log(file.name)

    );

    console.log('\nTo delete, run with --delete');

  }

}

main().catch(console.error);
 