// web/firebase-messaging-sw.js
//
// Service worker requis par Firebase Cloud Messaging sur le web — c'est ce
// qui permet de recevoir une notification même quand l'onglet/l'app est
// fermé(e). Doit être servi depuis LA RACINE du site (web/firebase-messaging-sw.js
// → https://tonsite.netlify.app/firebase-messaging-sw.js), pas dans un
// sous-dossier, sinon le navigateur ne peut pas lui donner la portée
// nécessaire pour intercepter les messages.
//
// ⚠️ À COMPLÉTER : remplace les 5 valeurs ci-dessous par celles de la
// section "web" de ton lib/firebase_options.dart généré par
// `flutterfire configure`. Ce ne sont PAS des secrets (ce sont les mêmes
// valeurs déjà publiques dans le bundle JS de l'app une fois buildée), donc
// aucun risque à les coder en dur ici.
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "REMPLACER_apiKey",
  authDomain: "REMPLACER_authDomain",
  projectId: "REMPLACER_projectId",
  storageBucket: "REMPLACER_storageBucket",
  messagingSenderId: "REMPLACER_messagingSenderId",
  appId: "REMPLACER_appId",
});

const messaging = firebase.messaging();

// Notification affichée par le navigateur quand un message arrive alors que
// l'onglet n'est pas au premier plan (ou fermé, si le navigateur le permet).
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || "MaTontine";
  const options = {
    body: payload.notification?.body || "",
    icon: "icons/Icon-192.png",
    badge: "icons/Icon-192.png",
    data: payload.data,
  };
  self.registration.showNotification(title, options);
});

// Clic sur la notification → ouvre/focus l'onglet de l'app.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ("focus" in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow("/");
    })
  );
});
