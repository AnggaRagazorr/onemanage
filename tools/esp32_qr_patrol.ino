/*
 * ============================================================
 *  ESP32 QR Patrol Checkpoint — Server Generated Token
 * ============================================================
 *
 *  Generates a QR code on button press by fetching a token
 *  from the Laravel backend via HTTP POST.
 *
 *  Format QR dari server: TOKEN:NamaArea:RandomString
 *
 *  Hardware:
 *    - ESP32 + W5500 Ethernet Module
 *    - TFT LCD (via TFT_eSPI)
 *    - Push button on GPIO 22
 * ============================================================
 */

#include "qrcodegen.h"
#include <Ethernet.h>
#include <EthernetClient.h>
#include <SPI.h>
#include <TFT_eSPI.h>

// ===================== KONFIGURASI HARDWARE =====================
#define W5500_SCK 14
#define W5500_MISO 12
#define W5500_MOSI 13
#define W5500_CS 5

#define BTN_PIN 22
#define BTN_ACTIVE_LOW 1

// ===================== SETTING APP =====================
#define QR_VERSION 6
#define ACTIVE_SECONDS 300       // Layar aktif 5 menit
#define AREA_NAME "Area Smoking" // HARUS sama naming area di sistem
#define DEBOUNCE_MS 250

// Kunci keamanan untuk endpoint server (Samakan dengan PATROL_DEVICE_KEY di
// .env Laravel)
static const char *DEVICE_KEY = "STEeZY_SECRET_2026";

// ===================== NETWORK =====================
byte mac[] = {0xDE, 0xAD, 0xBE, 0xEF, 0x32, 0x10};

// IP ESP32 (Kita taruh di 192.168.10.177)
IPAddress ip(192, 168, 10, 177);
IPAddress gateway(192, 168, 10, 1);
IPAddress subnet(255, 255, 255, 0);

// Server Laravel sekarang menggunakan IP LAN laptop (192.168.10.1)
IPAddress serverIP(192, 168, 10, 1);
uint16_t serverPort = 8000;

// ===================== STATE & BUFFERS =====================
TFT_eSPI tft = TFT_eSPI();
enum AppState { IDLE, ACTIVE };
AppState appState = IDLE;

uint32_t activeStartMs = 0;
unsigned long lastBtnMs = 0;
static uint8_t qrbuf[1400];
static uint8_t tempbuf[1400];
int qrDrawY0 = 0, qrDrawH = 0;

EthernetClient client;

// ===================== BUTTON HELPERS =====================
bool isButtonPressed() {
#if BTN_ACTIVE_LOW
  return digitalRead(BTN_PIN) == LOW;
#else
  return digitalRead(BTN_PIN) == HIGH;
#endif
}

// ===================== UI HELPERS =====================
void showIdle() {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
  tft.setCursor(24, 85);
  tft.println("PGASCOM Patrol");
  tft.setTextSize(1);
  tft.setCursor(10, 210);
  tft.print("IP: ");
  tft.println(Ethernet.localIP());
  tft.setCursor(10, 225);
  tft.print("Tekan tombol = Request QR");
  qrDrawH = 0;
}

void showBanner(const char *msg, uint16_t bg = TFT_RED,
                uint16_t fg = TFT_WHITE) {
  tft.fillRect(0, 0, 240, 26, bg);
  tft.setTextColor(fg, bg);
  tft.setTextSize(1);
  tft.setCursor(4, 8);
  tft.print(msg);
}

void updateCountdown(uint32_t s) {
  if (qrDrawH <= 0)
    return;
  int textY = qrDrawY0 + qrDrawH + 34;
  tft.fillRect(0, textY, 240, 34, TFT_BLACK);
  tft.setCursor(10, textY + 6);
  tft.setTextSize(2);
  tft.setTextColor(s > 10 ? TFT_GREEN : (s > 5 ? TFT_YELLOW : TFT_RED),
                   TFT_BLACK);
  tft.print("Exp: ");
  tft.print(s);
  tft.print("s");
}

void drawQR(const String &text, uint32_t sisa) {
  bool ok =
      qrcodegen_encodeText(text.c_str(), tempbuf, qrbuf, qrcodegen_Ecc_LOW,
                           QR_VERSION, QR_VERSION, qrcodegen_Mask_AUTO, true);
  if (!ok) {
    tft.fillScreen(TFT_BLACK);
    showBanner("QR encode gagal", TFT_RED, TFT_WHITE);
    return;
  }

  int size = qrcodegen_getSize(qrbuf);
  int scale = 6; // Diperbesar dari 3 menjadi 6
  int x0 = (tft.width() - (size * scale)) / 2;
  int y0 = 26;
  qrDrawY0 = y0;
  qrDrawH = size * scale;

  tft.fillScreen(TFT_BLACK);
  tft.fillRect(x0 - 4, y0 - 4, (size * scale) + 8, (size * scale) + 8,
               TFT_WHITE);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (qrcodegen_getModule(qrbuf, x, y)) {
        tft.fillRect(x0 + (x * scale), y0 + (y * scale), scale, scale,
                     TFT_BLACK);
      }
    }
  }

  tft.setTextColor(TFT_CYAN, TFT_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, y0 + qrDrawH + 8);
  tft.print("Area: ");
  tft.print(AREA_NAME);

  updateCountdown(sisa);
}

// ===================== SERVER COMMS =====================
String fetchTokenFromServer() {
  unsigned long t0 = millis();
  Serial.print("Connecting to server... ");
  if (!client.connect(serverIP, serverPort)) {
    Serial.println("Koneksi ke server gagal");
    return "";
  }
  unsigned long t1 = millis();
  Serial.print("Connected in ");
  Serial.print(t1 - t0);
  Serial.println(" ms");

  // Siapkan payload JSON
  String payload = "{\"area\":\"" + String(AREA_NAME) + "\"}";

  // Kirim HTTP POST Request
  client.println("POST /api/patrol-tokens HTTP/1.1");
  client.print("Host: ");
  client.println(serverIP);
  client.println("Content-Type: application/json");
  client.print("X-Device-Key: ");
  client.println(DEVICE_KEY);
  client.print("Content-Length: ");
  client.println(payload.length());
  client.println("Connection: close");
  client.println();
  client.println(payload);

  unsigned long t2 = millis();
  Serial.print("Request sent in ");
  Serial.print(t2 - t1);
  Serial.println(" ms");

  // Tunggu response (timeout 15s)
  unsigned long timeout = millis();
  while (!client.available()) {
    if (millis() - timeout > 15000) {
      Serial.println("Timeout tunggu response server (15s)");
      client.stop();
      return "";
    }
    delay(10);
  }

  unsigned long t3 = millis();
  Serial.print("Response arrived in ");
  Serial.print(t3 - t2);
  Serial.println(" ms");

  // Baca response secepatnya
  client.setTimeout(2000); // Set timeout stream ke 2 detik agar tidak hang lama
  String response = client.readString();

  unsigned long t4 = millis();
  Serial.print("Response read in ");
  Serial.print(t4 - t3);
  Serial.println(" ms");
  Serial.println("--- RAW RESPONSE ---");
  Serial.println(response);
  Serial.println("--------------------");

  // Parse token dari body JSON
  String token = "";
  int idx = response.indexOf("\"token\":\"");
  if (idx >= 0) {
    int startToken = idx + 9;
    int endToken = response.indexOf("\"", startToken);
    if (endToken > startToken) {
      token = response.substring(startToken, endToken);
    }
  }

  client.stop();
  return token;
}

void startActive() {
  tft.fillScreen(TFT_BLACK);
  showBanner("Loading Token...", TFT_BLUE, TFT_WHITE);

  String token = fetchTokenFromServer();

  if (token.length() > 0 && token.startsWith("TOKEN:")) {
    activeStartMs = millis();
    appState = ACTIVE;
    drawQR(token, ACTIVE_SECONDS);

    Serial.println("Token Berhasil Diterima:");
    Serial.println(token);
  } else {
    showBanner("Gagal Request Token", TFT_RED, TFT_WHITE);
    delay(3000);
    showIdle();
  }
}

// ===================== SETUP & LOOP =====================
void setup() {
  Serial.begin(115200);

#if BTN_ACTIVE_LOW
  pinMode(BTN_PIN, INPUT_PULLUP);
#else
  pinMode(BTN_PIN, INPUT_PULLDOWN);
#endif

  tft.init();
  tft.setRotation(0);
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(1);
  tft.setCursor(10, 30);
  tft.println("Starting system...");

  SPI.begin(W5500_SCK, W5500_MISO, W5500_MOSI, W5500_CS);
  Ethernet.init(W5500_CS);

  tft.println("Connecting LAN...");
  Ethernet.begin(mac, ip, gateway, subnet);
  delay(1200);

  if (Ethernet.hardwareStatus() == EthernetNoHardware) {
    tft.fillScreen(TFT_RED);
    tft.setCursor(10, 100);
    tft.println("W5500 ERROR!");
    Serial.println("W5500 tidak terdeteksi.");
    while (true) {
      delay(1);
    }
  }

  if (Ethernet.linkStatus() == LinkOFF) {
    tft.println("LAN cable unplugged");
    Serial.println("Warning: kabel LAN belum terpasang.");
  }

  showIdle();
  Serial.println("System ready. Tekan tombol untuk request QR dari server.");
}

void loop() {
  if (isButtonPressed() && (millis() - lastBtnMs > DEBOUNCE_MS)) {
    lastBtnMs = millis();
    if (appState == IDLE) { // Cegah request berlapis
      startActive();
    }
  }

  if (appState == ACTIVE) {
    static unsigned long lastTick = 0;
    if (millis() - lastTick >= 1000) {
      lastTick = millis();
      uint32_t elapsed = (millis() - activeStartMs) / 1000;

      if (elapsed >= ACTIVE_SECONDS) {
        appState = IDLE;
        showIdle();
      } else {
        updateCountdown(ACTIVE_SECONDS - elapsed);
      }
    }
  }

  Ethernet.maintain();
}
