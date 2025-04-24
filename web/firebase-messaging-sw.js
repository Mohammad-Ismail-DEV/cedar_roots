importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyBfa_34MItxWyWYF_Ck_QCwELJIxBv-v5U',
  appId: '1:344338108473:web:32df62ac876f925345bde8',
  messagingSenderId: '344338108473',
  projectId: 'cedar-roots-453719',
  authDomain: 'cedar-roots-453719.firebaseapp.com',
  storageBucket: 'cedar-roots-453719.firebasestorage.app',
});

const messaging = firebase.messaging();
