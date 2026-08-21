const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when SOS is triggered
exports.sendSOSNotification = functions.firestore
  .document('sos_alerts/{sosId}')
  .onCreate(async (snap, context) => {
    const sosData = snap.data();
    
    try {
      // Get user's contacts
      const contactsSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(sosData.userId)
        .collection('contacts')
        .get();

      const tokens = [];
      for (const doc of contactsSnapshot.docs) {
        const contact = doc.data();
        if (contact.fcmToken) {
          tokens.push(contact.fcmToken);
        }
      }

      // Also get user's own FCM token
      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(sosData.userId)
        .get();
      
      const userData = userDoc.data();
      if (userData && userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }

      if (tokens.length === 0) {
        console.log('No FCM tokens found');
        return;
      }

      const message = {
        notification: {
          title: '🚨 SAFEWALK SOS ALERT',
          body: 'Emergency! Your contact needs immediate help!',
        },
        data: {
          type: 'sos',
          userId: sosData.userId || '',
          latitude: String(sosData.latitude || 0),
          longitude: String(sosData.longitude || 0),
          sosId: sosData.sosId || '',
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log('SOS notification sent:', response.successCount, 'successful');
      
    } catch (error) {
      console.error('Error sending SOS notification:', error);
    }
  });

// Send notification when check-in timer expires
exports.sendCheckinTimeoutNotification = functions.firestore
  .document('auto_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alertData = snap.data();
    
    try {
      const contactsSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(alertData.userId)
        .collection('contacts')
        .get();

      const tokens = [];
      for (const doc of contactsSnapshot.docs) {
        const contact = doc.data();
        if (contact.fcmToken) {
          tokens.push(contact.fcmToken);
        }
      }

      if (tokens.length === 0) {
        console.log('No FCM tokens found');
        return;
      }

      const message = {
        notification: {
          title: '⚠️ SAFEWALK CHECK-IN TIMEOUT',
          body: 'Your contact did not check in on time!',
        },
        data: {
          type: 'checkin_timeout',
          userId: alertData.userId || '',
          latitude: String(alertData.latitude || 0),
          longitude: String(alertData.longitude || 0),
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log('Check-in timeout notification sent:', response.successCount);
      
    } catch (error) {
      console.error('Error sending check-in timeout notification:', error);
    }
  });

// Send notification when route deviation detected
exports.sendRouteDeviationNotification = functions.firestore
  .document('deviation_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alertData = snap.data();
    
    try {
      const contactsSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(alertData.userId)
        .collection('contacts')
        .get();

      const tokens = [];
      for (const doc of contactsSnapshot.docs) {
        const contact = doc.data();
        if (contact.fcmToken) {
          tokens.push(contact.fcmToken);
        }
      }

      if (tokens.length === 0) {
        console.log('No FCM tokens found');
        return;
      }

      const message = {
        notification: {
          title: '🛑 SAFEWALK ROUTE DEVIATION',
          body: 'Your contact is off their expected route!',
        },
        data: {
          type: 'route_deviation',
          userId: alertData.userId || '',
          latitude: String(alertData.currentLatitude || 0),
          longitude: String(alertData.currentLongitude || 0),
          deviation: String(alertData.deviationDistance || 0),
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log('Route deviation notification sent:', response.successCount);
      
    } catch (error) {
      console.error('Error sending route deviation notification:', error);
    }
  });

// Send notification when session starts
exports.sendSessionStartNotification = functions.firestore
  .document('sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const sessionData = snap.data();
    
    try {
      const contactsSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(sessionData.userId)
        .collection('contacts')
        .get();

      const tokens = [];
      for (const doc of contactsSnapshot.docs) {
        const contact = doc.data();
        if (contact.fcmToken) {
          tokens.push(contact.fcmToken);
        }
      }

      if (tokens.length === 0) return;

      const message = {
        notification: {
          title: '🚶 SAFEWALK SESSION STARTED',
          body: 'Your contact has started a safety session.',
        },
        data: {
          type: 'session_start',
          sessionId: sessionData.sessionId || '',
          userId: sessionData.userId || '',
        },
        tokens: tokens,
      };

      await admin.messaging().sendMulticast(message);
      
    } catch (error) {
      console.error('Error sending session notification:', error);
    }
  });