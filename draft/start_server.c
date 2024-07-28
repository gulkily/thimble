#include "mongoose.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static const char *s_http_port = "8000";
static const char *s_web_directory = ".";

static void generate_report() {
    printf("Generating report...\n");
    system("python generate_report.py");
}

static void check_and_generate_report() {
    const char *html_file = "index.html";
    struct stat st;
    time_t current_time = time(NULL);

    if (stat(html_file, &st) == -1 || difftime(current_time, st.st_mtime) > 60) {
        printf("%s is older than 60 seconds or does not exist. Running generate_report.py...\n", html_file);
        generate_report();
    } else {
        printf("%s is up-to-date.\n", html_file);
    }
}

static void serve_text_file(struct mg_connection *c, const char *path) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        mg_http_reply(c, 404, NULL, "File not found");
        return;
    }

    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *content = malloc(file_size + 1);
    fread(content, 1, file_size, file);
    content[file_size] = '\0';
    fclose(file);

    const char *html_template = 
        "<!DOCTYPE html>"
        "<html lang=\"en\">"
        "<head>"
            "<meta charset=\"UTF-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
            "<title>%s</title>"
            "<style>"
                "body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }"
                "pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }"
            "</style>"
        "</head>"
        "<body>"
            "<h1>%s</h1>"
            "<pre>%s</pre>"
        "</body>"
        "</html>";

    char *filename = strrchr(path, '/');
    if (filename == NULL) filename = (char *)path;
    else filename++;

    char *html_content = malloc(strlen(html_template) + strlen(filename) * 2 + strlen(content) + 1);
    sprintf(html_content, html_template, filename, filename, content);

    mg_http_reply(c, 200, "Content-Type: text/html; charset=utf-8\r\n", html_content);

    free(content);
    free(html_content);
}

static void ev_handler(struct mg_connection *c, int ev, void *ev_data, void *fn_data) {
    if (ev == MG_EV_HTTP_MSG) {
        struct mg_http_message *hm = (struct mg_http_message *) ev_data;
        
        if (mg_http_match_uri(hm, "/")) {
            check_and_generate_report();
            mg_http_serve_dir(c, hm, s_web_directory);
        } else if (mg_match(hm->uri, mg_str("*.txt"), NULL)) {
            char path[256];
            mg_snprintf(path, sizeof(path), "%s%.*s", s_web_directory, (int) hm->uri.len, hm->uri.ptr);
            serve_text_file(c, path);
        } else {
            mg_http_serve_dir(c, hm, s_web_directory);
        }
    }
}

int main(int argc, char *argv[]) {
    struct mg_mgr mgr;
    struct mg_connection *c;

    mg_mgr_init(&mgr);
    c = mg_http_listen(&mgr, s_http_port, ev_handler, NULL);
    if (c == NULL) {
        printf("Error starting server on port %s\n", s_http_port);
        return 1;
    }

    printf("Starting Mongoose web server on port %s\n", s_http_port);
    for (;;) mg_mgr_poll(&mgr, 1000);
    mg_mgr_free(&mgr);

    return 0;
}
