use std::fs;
use std::io::{self, Read};
use std::net::TcpListener;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Duration, SystemTime};
use tiny_http::{Server, Response, Header};
use html_escape::encode_text;
use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value_t = 8000)]
    port: u16,

    #[arg(short, long, default_value = ".")]
    directory: String,
}

fn main() -> io::Result<()> {
    let args = Args::parse();
    
    std::env::set_current_dir(&args.directory)?;
    
    let server = Server::http(format!("0.0.0.0:{}", args.port)).unwrap();
    println!("Server running on http://0.0.0.0:{}/", args.port);

    for request in server.incoming_requests() {
        let url = request.url().to_string();
        
        if url == "/" {
            check_and_generate_report();
            serve_file(request, "index.html")?;
        } else if url.ends_with(".txt") {
            serve_text_file(request, &url[1..])?;
        } else {
            serve_file(request, &url[1..])?;
        }
    }

    Ok(())
}

fn check_and_generate_report() {
    let html_file = Path::new("index.html");
    if !html_file.exists() || is_file_older_than_60_seconds(html_file) {
        println!("index.html is older than 60 seconds or does not exist. Running generate_report.py...");
        Command::new("python")
            .arg("generate_report.py")
            .status()
            .expect("Failed to execute generate_report.py");
    } else {
        println!("index.html is up-to-date.");
    }
}

fn is_file_older_than_60_seconds(path: &Path) -> bool {
    path.metadata()
        .and_then(|metadata| metadata.modified())
        .map(|modified| {
            SystemTime::now()
                .duration_since(modified)
                .unwrap_or(Duration::from_secs(0))
                > Duration::from_secs(60)
        })
        .unwrap_or(true)
}

fn serve_file(request: tiny_http::Request, filename: &str) -> io::Result<()> {
    let path = Path::new(filename);
    let content = fs::read(path)?;
    let response = Response::from_data(content);
    request.respond(response).map_err(|e| io::Error::new(io::ErrorKind::Other, e))
}

fn serve_text_file(request: tiny_http::Request, filename: &str) -> io::Result<()> {
    let path = Path::new(filename);
    let mut content = String::new();
    fs::File::open(path)?.read_to_string(&mut content)?;

    let html_content = format!(
        r#"
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{}</title>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }}
                pre {{ background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }}
            </style>
        </head>
        <body>
            <h1>{}</h1>
            <pre>{}</pre>
        </body>
        </html>
        "#,
        path.file_name().unwrap().to_str().unwrap(),
        path.file_name().unwrap().to_str().unwrap(),
        encode_text(&content)
    );

    let response = Response::from_string(html_content)
        .with_header(Header::from_bytes(&b"Content-Type"[..], &b"text/html; charset=utf-8"[..]).unwrap());

    request.respond(response).map_err(|e| io::Error::new(io::ErrorKind::Other, e))
}
