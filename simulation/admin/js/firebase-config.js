// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCYzsTkqeRD8ayh3xU54LXVC9xjZVd963Y",
  authDomain: "afwms-d3141.firebaseapp.com",
  projectId: "afwms-d3141",
  storageBucket: "afwms-d3141.firebasestorage.app",
  messagingSenderId: "223103795490",
  appId: "1:223103795490:web:d54b3ccd76fc336373e57b",
  measurementId: "G-6GW2WQFR4X",
  databaseURL: "https://afwms-d3141-default-rtdb.firebaseio.com/" // Added Realtime DB URL
};

// Initialize primary Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.database();
const firestoreDb = firebase.firestore();

// Initialize secondary Firebase app for creating users without signing out the current user
const secondaryApp = firebase.initializeApp(firebaseConfig, "Secondary");
const secondaryAuth = secondaryApp.auth();

// Export instances to be used in other files
window.firebaseConfig = firebaseConfig;
window.db = db;
window.firestoreDb = firestoreDb;
window.auth = auth;
window.secondaryAuth = secondaryAuth;
