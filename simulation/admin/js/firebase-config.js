// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCYzsTkqeRD8ayh3xU54LXVC9xjZVd963Y",
  authDomain: "afwms-d3141.firebaseapp.com",
  projectId: "afwms-d3141",
  storageBucket: "afwms-d3141.firebasestorage.app",
  messagingSenderId: "223103795490",
  appId: "1:223103795490:web:d54b3ccd76fc336373e57b",
  measurementId: "G-6GW2WQFR4X",
  databaseURL: "https://afwms-d3141-default-rtdb.firebaseio.com" // RTDB URL matched to Firebase SDK region warning
};

// Initialize primary Firebase
firebase.initializeApp(firebaseConfig);
const auth = (typeof firebase.auth === 'function') ? firebase.auth() : null;
const db = (typeof firebase.database === 'function') ? firebase.database() : null;
const firestoreDb = (typeof firebase.firestore === 'function') ? firebase.firestore() : null;

// Initialize secondary Firebase app for creating users without signing out the current user
let secondaryAuth = null;
try {
  if (typeof firebase.auth === 'function') {
    const secondaryApp = firebase.initializeApp(firebaseConfig, "Secondary");
    secondaryAuth = secondaryApp.auth();
  }
} catch (e) {
  // ignore if it already exists
}

// Export instances to be used in other files
window.firebaseConfig = firebaseConfig;
window.db = db;
window.firestoreDb = firestoreDb;
window.auth = auth;
window.secondaryAuth = secondaryAuth;
