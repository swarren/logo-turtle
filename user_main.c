/******************************************************************************
 * Copyright 2013-2014 Espressif Systems (Wuxi)
 * Copyright (c) 2014-2015, Stephen Warren
 *
 * FileName: user_main.c
 *
 * Description: entry file of user application
 *
 * Modification history:
 *     2014/12/1, v1.0 create this file.
 *     2014/12/?? All kinds of changes by swarren
*******************************************************************************/

#include "esp_common.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "lwip/sockets.h"
#include "lwip/dns.h"
#include "lwip/netdb.h"

#include "udhcp/dhcpd.h"

#include "uart.h"

void init_task(void *params) {
    bool bret;

    printf("init_task running\r\n");

    wifi_set_opmode(SOFTAP_MODE);

    static struct ip_info ipinfo;
    ipinfo.gw.addr = ipaddr_addr("192.168.145.253");
    ipinfo.ip.addr = ipaddr_addr("192.168.145.253");
    ipinfo.netmask.addr = ipaddr_addr("255.255.255.0");
    bret = wifi_set_ip_info(SOFTAP_IF, &ipinfo);
    printf("wifi_set_ip_info returns %d\r\n", (int)bret);

    static struct dhcp_info di = {
        .max_leases = 10,
        .auto_time = 60,
        .decline_time = 60,
        .conflict_time = 60,
        .offer_time = 60,
        .min_lease_sec = 60,
    };
    di.start_ip = ipaddr_addr("192.168.145.100");
    di.end_ip = ipaddr_addr("192.168.145.103");
    bret = dhcp_set_info(&di);
    printf("dhcp_set_info returns %d\r\n", (int)bret);

    udhcpd_start();

    static struct softap_config apcfg = {
        .ssid = "WDO-TURTLE-1",
        .ssid_len = 12,
        .password = "password",
        .channel = 1,
        .authmode = AUTH_WPA_PSK,
        .ssid_hidden = 0,
        .max_connection = 5,
    };
    bret = wifi_softap_set_config(&apcfg);
    printf("wifi_softap_set_config returns %d\r\n", (int)bret);

    printf("AP config set!\r\n");

    vTaskDelete(NULL);
}

int uart_tcp_gen_server_sock(void) {
    struct sockaddr_in server_addr;
    int server_sock;
    int ret;

    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(23);

    server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock == -1) {
        printf("socket() failed\n");
        return -1;
    }

    ret = bind(server_sock, (struct sockaddr *)(&server_addr), sizeof(struct sockaddr));
    if (ret == -1) {
        printf("bind() failed\n");
        close(server_sock);
        return -1;
    }

    ret = listen(server_sock, 5);
    if (ret == -1) {
        printf("listen() failed\n");
        close(server_sock);
        return -1;
    }

    return server_sock;
}

int uart_tcp_client_sock = -1;

void uart_rx_char(char c) {
    write(uart_tcp_client_sock, &c, 1);
}

void uart_tcp_handle_client(int s) {
    char buf[129];
    int count, i;

    for (;;) {
        count = read(s, buf, sizeof(buf) - 1);
        if (count <= 0)
            return;
        buf[count] = '\0';

        for (i = 0; i < count; i++) {
            uart_tx_one_char(UART0, buf[i]);
        }
    }
}

void uart_tcp_task(void *params) {
    int server_sock;
    int recbytes;

    printf("uart_tcp_task running\r\n");

    server_sock = uart_tcp_gen_server_sock();
    if (server_sock < 0) {
        printf("uart_tcp_gen_server_sock() failed\r\n");
        vTaskDelete(NULL);
    }

    for (;;) {
        uart_tcp_client_sock = accept(server_sock, (struct sockaddr *)NULL, NULL);
        if (uart_tcp_client_sock == -1) {
            printf("accept() failed \n");
            continue;
        }

        uart_tcp_handle_client(uart_tcp_client_sock);
        close(uart_tcp_client_sock);
    }
}

int mdns_gen_sock(void) {
    struct sockaddr_in server_addr;
    int server_sock;
    int ret;

    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(5353);

    server_sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_sock == -1) {
        printf("socket() failed\n");
        return -1;
    }

    ret = bind(server_sock, (struct sockaddr *)(&server_addr), sizeof(struct sockaddr));
    if (ret == -1) {
        printf("bind() failed\n");
        close(server_sock);
        return -1;
    }

    return server_sock;
}

static char mdns_buf[512] = {"Hello!"};
static struct sockaddr_in dstaddr;

void mdns_task(void *params) {
    int ret, sock;

    printf("mdns_task running\r\n");

#if 0
    ret = igmp_joingroup(INADDR_ANY, inet_addr("224.0.0.251"));
    if (ret != ERR_OK) {
        printf("igmp_joingroup() failed: %d\r\n", ret);
        vTaskDelete(NULL);
    }
#endif

    sock = mdns_gen_sock();
    if (sock < 0) {
        printf("mdns_gen_sock() failed: %d\r\n", errno);
        vTaskDelete(NULL);
    }

    memset(&dstaddr, 0, sizeof(dstaddr));
    dstaddr.sin_family = AF_INET;
    dstaddr.sin_port = htons(5353);
    dstaddr.sin_addr.s_addr = inet_addr("224.0.0.251"); //INADDR_BROADCAST; //htonl((224 << 24) | 251);

    for (;;) {
        printf("mdns: calling sendto()\r\n", errno);
        ret = sendto(sock, mdns_buf, sizeof mdns_buf, 0, (struct sockaddr *)&dstaddr, sizeof dstaddr);
        if (ret == -1)
            printf("sendto() failed; errno=%d\r\n", errno);
        vTaskDelay((30000 / 10 /* 3s */) / 10 /* ticks/ms */);
    }
}

void ICACHE_FLASH_ATTR user_init(void) {
    uart_init();

    xTaskCreate(init_task, "init", 256 * 4, NULL, 2, NULL);
    /*
     * I'm not sure if I ever actually used the following two tasks; this code
     * is very much a work-in-progress.
     */
    xTaskCreate(mdns_task, "mdns", 256 * 4, NULL, 2, NULL);
    xTaskCreate(uart_tcp_task, "uart", 256 * 4, NULL, 2, NULL);
}
