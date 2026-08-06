// Import and configure the Firebase SDK
// These scripts are made available when the app is served or built on Flutter
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCObagG7DklXPDWYEAuVVQg2YFJrID6-Jg",
  authDomain: "hadir-app-d5cfb.firebaseapp.com",
  projectId: "hadir-app-d5cfb",
  storageBucket: "hadir-app-d5cfb.firebasestorage.app",
  messagingSenderId: "870519253162",
  appId: "1:870519253162:web:08488990c9c0cf010308d3"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("Handling background message on Web", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});
