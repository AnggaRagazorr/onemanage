importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyDahPhudNz8RydRD_-rGq6Jj17C-0XFTB0",
  authDomain: "sekuriti.firebaseapp.com",
  projectId: "sekuriti",
  storageBucket: "sekuriti.firebasestorage.app",
  messagingSenderId: "884699382927",
  appId: "1:884699382927:web:a3c02b10c4bca29ff2dcfa",
  measurementId: "G-7R5QBM0PEN",
});

firebase.messaging();
