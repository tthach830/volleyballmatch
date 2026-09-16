// SetMatch Beach Service Worker for Web Push Notifications

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

// Handle incoming background Push Notification
self.addEventListener("push", (event) => {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: "🏐 Volleyball Match Alert", body: event.data.text() };
    }
  }

  const title = data.title || "🏐 Volleyball Match Game Confirmed!";
  const options = {
    body: data.body || "You've been paired for a beach volleyball set match! Tap to view details.",
    icon: "assets/slug.png",
    badge: "assets/slug.png",
    vibrate: [200, 100, 200],
    tag: "volleyballmatch-game-alert",
    renotify: true,
    data: {
      url: data.url || "./index.html"
    }
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

// Handle notification tap / click
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.url || "./index.html";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (let client of windowClients) {
        if (client.url.includes("index.html") && "focus" in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
