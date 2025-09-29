importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBSl6tHzf6x-WQAC4ecuuquoUGtwFfvUn8',
  appId: '1:641037176066:web:placeholder',
  messagingSenderId: '641037176066',
  projectId: 'book-3d7c1',
  authDomain: 'book-3d7c1.firebaseapp.com',
  storageBucket: 'book-3d7c1.appspot.com',
  measurementId: 'G-PLACEHOLDER',
});

firebase.messaging();
