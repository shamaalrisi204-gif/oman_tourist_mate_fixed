const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
 credential: admin.credential.cert(serviceAccount),
 storageBucket: 'the-oman-tourist-mate-27766.firebasestorage.app',
});
const db = admin.firestore();
const bucket = admin.storage().bucket();
async function testConnection() {
 try {
   const collections = await db.listCollections();
   console.log('Firebase connected successfully!');
   console.log('Firestore collections:');
   collections.forEach((collection) => {
     console.log('-', collection.id);
   });
   console.log('Storage bucket:', bucket.name);
 } catch (error) {
   console.error('Firebase connection failed:', error);
 }
}
testConnection();