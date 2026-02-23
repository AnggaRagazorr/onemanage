self.addEventListener('notificationclick', (event) => {
    const targetUrl = event?.notification?.data?.url || '/web/#/dashboard';
    event.notification.close();

    event.waitUntil((async () => {
        const allClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
        for (const client of allClients) {
            if ('focus' in client) {
                client.navigate(targetUrl);
                client.focus();
                return;
            }
        }
        if (clients.openWindow) {
            await clients.openWindow(targetUrl);
        }
    })());
});

