/*
 * ============================================================
 *  ESP32 QR Patrol Checkpoint — Dynamic QR with HMAC
 * ============================================================
 *
 *  Generates a QR code every 10 seconds with format:
 *      NamaArea|UnixTimestamp|HMAC_SHA256
 *
 *  The area name is STATIC (hardcoded per device).
 *  The timestamp and HMAC change every cycle.
 *
 *  Hardware:
 *    - ESP32 (any variant)
 *    - SSD1306 OLED 128x64 (I2C)
 *    - WiFi for NTP time sync
 *
 *  Libraries needed (install via Arduino Library Manager):
 *    - Adafruit SSD1306
 *    - Adafruit GFX
 *    - qrcode (by Richard Moore)
 *    - mbedtls (built-in with ESP32 Arduino core)
 *
 *  IMPORTANT: The SECRET_KEY below must match the
 *  QR_PATROL_SECRET in your Laravel .env file!
 * ============================================================
 */

#include <WiFi.h>
#include <time.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "qrcode.h"
#include "mbedtls/md.h"

// ===================== CONFIG =====================
// WiFi credentials
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Area identity — CHANGE THIS PER DEVICE
// Options: "AreaLuar", "AreaBalkon", "AreaSmoking"
const char* AREA_NAME = "AreaLuar";

// HMAC Secret — MUST MATCH Laravel .env QR_PATROL_SECRET
const char* SECRET_KEY = "pgncom_patrol_2026_secret";

// QR refresh interval (seconds)
const int QR_REFRESH_SECONDS = 10;

// NTP server
const char* NTP_SERVER = "pool.ntp.org";
const long  GMT_OFFSET = 7 * 3600;  // WIB (UTC+7)
const int   DST_OFFSET = 0;

// OLED config
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_ADDR     0x3C
// ==================================================

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

void setup() {
    Serial.begin(115200);
    Serial.println("\n[QR Patrol] Starting...");

    // Init OLED
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("[QR Patrol] OLED init FAILED");
        while (true) delay(1000);
    }
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Connecting WiFi...");
    display.display();

    // Connect WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("\n[QR Patrol] WiFi connected: %s\n", WiFi.localIP().toString().c_str());
    } else {
        Serial.println("\n[QR Patrol] WiFi FAILED — using internal clock");
    }

    // Sync NTP time
    configTime(GMT_OFFSET, DST_OFFSET, NTP_SERVER);
    Serial.println("[QR Patrol] Waiting for NTP sync...");

    struct tm timeinfo;
    if (getLocalTime(&timeinfo, 10000)) {
        Serial.println("[QR Patrol] NTP synced OK");
    } else {
        Serial.println("[QR Patrol] NTP sync failed — timestamps may be wrong");
    }

    Serial.printf("[QR Patrol] Area: %s\n", AREA_NAME);
    Serial.printf("[QR Patrol] Refresh: every %d seconds\n", QR_REFRESH_SECONDS);
}

/**
 * Compute HMAC-SHA256 and return as lowercase hex string.
 * Message format: "AreaName|timestamp"
 */
String computeHMAC(const char* area, unsigned long timestamp) {
    char message[128];
    snprintf(message, sizeof(message), "%s|%lu", area, timestamp);

    byte hmacResult[32];
    mbedtls_md_context_t ctx;
    mbedtls_md_type_t md_type = MBEDTLS_MD_SHA256;

    mbedtls_md_init(&ctx);
    mbedtls_md_setup(&ctx, mbedtls_md_info_from_type(md_type), 1); // 1 = HMAC
    mbedtls_md_hmac_starts(&ctx, (const unsigned char*)SECRET_KEY, strlen(SECRET_KEY));
    mbedtls_md_hmac_update(&ctx, (const unsigned char*)message, strlen(message));
    mbedtls_md_hmac_finish(&ctx, hmacResult);
    mbedtls_md_free(&ctx);

    // Convert to hex string
    String hex = "";
    for (int i = 0; i < 32; i++) {
        char buf[3];
        snprintf(buf, sizeof(buf), "%02x", hmacResult[i]);
        hex += buf;
    }
    return hex;
}

/**
 * Build the full QR payload string.
 * Format: "AreaName|UnixTimestamp|HmacHex"
 */
String buildQrPayload() {
    time_t now = time(nullptr);
    unsigned long timestamp = (unsigned long)now;
    String hmac = computeHMAC(AREA_NAME, timestamp);

    String payload = String(AREA_NAME) + "|" + String(timestamp) + "|" + hmac;
    return payload;
}

/**
 * Draw QR code on the OLED display.
 */
void displayQR(const String& payload) {
    QRCode qrcode;
    uint8_t qrcodeData[qrcode_getBufferSize(6)]; // version 6 = up to 134 chars
    qrcode_initText(&qrcode, qrcodeData, 6, ECC_LOW, payload.c_str());

    display.clearDisplay();

    // Calculate scaling and position to center QR on display
    int moduleSize = min(SCREEN_WIDTH, SCREEN_HEIGHT) / qrcode.size;
    if (moduleSize < 1) moduleSize = 1;

    int qrPixelSize = qrcode.size * moduleSize;
    int offsetX = (SCREEN_WIDTH - qrPixelSize) / 2;
    int offsetY = (SCREEN_HEIGHT - qrPixelSize) / 2;

    for (uint8_t y = 0; y < qrcode.size; y++) {
        for (uint8_t x = 0; x < qrcode.size; x++) {
            if (qrcode_getModule(&qrcode, x, y)) {
                display.fillRect(
                    offsetX + x * moduleSize,
                    offsetY + y * moduleSize,
                    moduleSize, moduleSize,
                    SSD1306_WHITE
                );
            }
        }
    }

    display.display();
}

void loop() {
    String payload = buildQrPayload();

    Serial.printf("[QR Patrol] QR: %s\n", payload.c_str());
    displayQR(payload);

    delay(QR_REFRESH_SECONDS * 1000);
}
