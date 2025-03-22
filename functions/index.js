const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Firebase Admin SDK başlatılıyor
admin.initializeApp();

// SMTP için Nodemailer kullanımı
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'bees2443@gmail.com',
    pass: 'knby opnr wnmq rmug',  // Bu şifrenizi doğru şekilde buraya eklemelisiniz.
  }
});

// Kullanıcı banlandığında e-posta gönderme fonksiyonu
exports.sendBanEmail = functions.firestore
  .document('banned_users/{userId}') // banned_users koleksiyonundaki her yeni belge eklendiğinde tetiklenir
  .onCreate(async (snapshot, context) => {
    const userId = snapshot.data().userId;

    // Kullanıcı bilgilerini al
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('User not found!');
      return null;
    }

    const userEmail = userDoc.data().emailAddress;
    const firstName = userDoc.data().firstName;
    const lastName = userDoc.data().lastName;

    // Yasaklama bilgilerini al
    const banReason = snapshot.data().banReason;
    const banPeriod = snapshot.data().banPeriod;
    const banDate = snapshot.data().banDate.toDate();
    const banType = banPeriod === 'Permanent' ? 'permanent' : 'temporary';
    let banEndDate = null;
    let subject = '';

    if (banType === 'temporary') {
      const duration = parseInt(banPeriod); // Ban süresi gün cinsinden varsayalım
      banEndDate = new Date(banDate);
      banEndDate.setDate(banEndDate.getDate() + duration);
      subject = 'Your Account Has Been Temporarily Banned';
    } else {
      subject = 'Your Account Has Been Permanently Banned';
    }

    // E-posta içeriği oluşturuluyor
    const emailBody = `
      Hello ${firstName} ${lastName},

      We regret to inform you that your account has been banned.

      Ban Type: ${banType === 'temporary' ? `Temporary (until ${banEndDate.toDateString()})` : 'Permanent'}
      Reason for Ban: ${banReason}

      If you believe this was a mistake, please contact support.

      Kind regards,
      The BEES Support Team
    `;

    // E-posta gönderimi
    const mailOptions = {
      from: 'bees2443@gmail.com',
      to: userEmail,
      subject: subject,
      text: emailBody,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('Ban email sent successfully!');
    } catch (error) {
      console.error('Error sending email:', error);
    }
    return null;
  });
