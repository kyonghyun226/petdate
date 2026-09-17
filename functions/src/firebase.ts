import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

// Single default app for callables + FCM triggers.
initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();
