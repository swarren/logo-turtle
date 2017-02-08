#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>

#define DEBUG 0

ESP8266WebServer web_server(80);

bool web_client_is_sta() {
  return web_server.client().localIP() == WiFi.localIP();
}

bool web_client_is_ap() {
  return web_server.client().localIP() == WiFi.softAPIP();
}

bool str_isprint(String s) {
  for (int i = 0; i < s.length(); i++)
    if (!isprint(s[i]))
      return false;
  return true;
}

void handle_http_not_found() {
  web_server.send(404, "text/plain", "Not Found");
}

const char html_root[] = { "\
<html\
<head>\
<title>ESP8266 Turtle</title>\
</head>\
<body>\
<form method=\"POST\" action=\"/\">\
Command:\
<br/>\
<textarea name=\"command\" rows=\"20\" cols=\"80\"></textarea>\
<br/>\
<input type=\"submit\" value=\"Execute\"/>\
</form>\
</body>\
</html>\
"
};

void handle_http_root() {
#if DEBUG
  Serial.println("handle_http_root()");
#endif

  if (web_server.hasArg("command")) {
    String command = web_server.arg("command");
    if (command.length()) {
        command.replace("\r", "");
        if (!command.endsWith("\n"))
            command.concat("\n");
        const char *c = command.c_str();
        while (*c) {
          Serial.print(*c);
          if (*c == '\n')
            Serial.readStringUntil(':');
          c++;
        }
    }
  }
  web_server.send(200, "text/html", html_root);
#if DEBUG
  Serial.println("handle_http_root() DONE");
#endif
}

void setup() {
  Serial.begin(57600);
#if DEBUG
  delay(250);
  Serial.println("");
  Serial.println("setup()");
#endif

  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(IPAddress(192, 168, 50, 1), IPAddress(192, 168, 50, 1), IPAddress(255, 255, 255, 0));
  WiFi.softAP("ESP-turtle", "ESP-turtle");

  Serial.setTimeout(30000);
  while (Serial.available())
    Serial.read();
  Serial.print("0\n");
  Serial.readStringUntil(':');

  web_server.onNotFound(handle_http_not_found);
  web_server.on("/", HTTP_ANY, handle_http_root);
  web_server.begin();

#if DEBUG
  Serial.println("setup() DONE");
#endif
}

void loop() {
#if DEBUG
  {
    static unsigned long tl;
    unsigned long t;
    t = millis();
    if (t - tl > 1000) {
      tl = t;
      Serial.println("loop()");
      Serial.print("AP IP: ");
      Serial.println(WiFi.softAPIP().toString());
    }
  }
#endif
  web_server.handleClient();
}
