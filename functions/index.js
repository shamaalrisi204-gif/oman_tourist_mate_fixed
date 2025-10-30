// Node.js 20 (Gen2)
const { onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions, logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({
 region: 'us-central1',
 memoryMiB: 256,
 timeoutSeconds: 60,
});
// 6 أرقام عشوائية
function genOtp() {
 return Math.floor(100000 + Math.random() * 900000).toString();
}
// إرسال الكود
exports.sendVerificationCode = onRequest(
 { secrets: ['GMAIL_EMAIL', 'GMAIL_APP_PASSWORD'] },
 async (req, res) => {
   try {
     const email = (req.body?.data?.email || '').trim().toLowerCase();
     if (!email) return res.status(400).json({ success: false, message: 'MISSING_EMAIL' });
     const code = genOtp();
     const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 دقائق
     // خزّن الكود
     await db.collection('otp').doc(email).set(
       {
         code,
         expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
         createdAt: admin.firestore.FieldValue.serverTimestamp(),
       },
       { merge: true }
     );
     // إعداد Gmail (App Password)
     const transporter = nodemailer.createTransport({
       service: 'gmail',
       auth: {
         user: process.env.GMAIL_EMAIL,
         pass: process.env.GMAIL_APP_PASSWORD,
       },
     });
     await transporter.sendMail({
       from: process.env.GMAIL_EMAIL,
       to: email,
       subject: 'رمز التحقق الخاص بك',
       text: `رمز التحقق الخاص بك هو: ${code} (صالح لمدة 5 دقائق)`,
     });
logger.info(`OTP ${code} sent to ${email}`);
     return res.status(200).json({ success: true, message: 'OTP sent' });
   } catch (err) {
     logger.error('sendVerificationCode failed', err);
     return res.status(500).json({ success: false, message: err?.message || 'Server error' });
   }
 }
);
// التحقق من الكود
exports.verifyOtpCode = onRequest(async (req, res) => {
 try {
   const email = (req.body?.data?.email || '').trim().toLowerCase();
   const code = (req.body?.data?.code || '').toString().trim();
   if (!email || !code) return res.status(400).json({ success: false, message: 'MISSING' });
   const snap = await db.collection('otp').doc(email).get();
   if (!snap.exists) return res.status(400).json({ success: false, message: 'NOT_FOUND' });
   const { code: stored, expiresAt } = snap.data() || {};
   // منتهي الصلاحية؟
   if (expiresAt?.toDate && expiresAt.toDate() < new Date()) {
     await db.collection('otp').doc(email).delete().catch(() => {});
     return res.status(400).json({ success: false, message: 'EXPIRED' });
   }
   if (stored !== code) return res.status(400).json({ success: false, message: 'INVALID' });
   // نجاح
   await db.collection('otp').doc(email).delete().catch(() => {});
   return res.status(200).json({ success: true });
 } catch (err) {
   logger.error('verifyOtpCode failed', err);
   return res.status(500).json({ success: false, message: err?.message || 'Server error' });
 }
});