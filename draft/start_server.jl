# start_server.jl
# to run: julia start_server.jl

#using Pkg
#Pkg.add("HTTP")
#Pkg.add("Dates")
#Pkg.add("JSON")

using HTTP
using Dates
using JSON

struct CustomHTTPRequestHandler
    directory::String
end

function check_and_generate_report(handler::CustomHTTPRequestHandler)
    report_file = joinpath(handler.directory, "report.txt")
    if !isfile(report_file) || (time() - mtime(report_file)) > 3600
        generate_report(handler)
    end
end

function generate_report(handler::CustomHTTPRequestHandler)
    report_content = "Report generated at: $(now())\n\n"
    report_content *= "Files in directory:\n"

    for file in readdir(handler.directory)
        report_content *= "- $file\n"
    end

    open(joinpath(handler.directory, "report.txt"), "w") do io
        write(io, report_content)
    end
end

function serve_file(handler::CustomHTTPRequestHandler, filename::String)
    filepath = joinpath(handler.directory, filename)
    if isfile(filepath)
        content = read(filepath)
        mime_type = get_mime_type(filepath)
        return HTTP.Response(200, ["Content-Type" => mime_type], body=content)
    else
        return HTTP.Response(404, "File not found")
    end
end

function serve_text_file(handler::CustomHTTPRequestHandler, uri::String)
    filepath = joinpath(handler.directory, uri[2:end])
    if isfile(filepath)
        content = read(filepath, String)
        html_content = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>$(basename(filepath))</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
                pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
            </style>
        </head>
        <body>
            <h1>$(basename(filepath))</h1>
            <pre>$(escape_html(content))</pre>
        </body>
        </html>
        """
        return HTTP.Response(200, ["Content-Type" => "text/html"], body=html_content)
    else
        return HTTP.Response(404, "File not found")
    end
end

function get_mime_type(filepath::String)
    mime_types = Dict(
        "txt" => "text/plain",
        "html" => "text/html",
        "css" => "text/css",
        "js" => "application/javascript",
        "json" => "application/json",
        "png" => "image/png",
        "jpg" => "image/jpeg",
        "gif" => "image/gif"
    )
    ext = lowercase(splitext(filepath)[2][2:end])
    return get(mime_types, ext, "application/octet-stream")
end

function escape_html(s::String)
    return replace(s, r"[&<>\"']" => m -> Dict('&'=>"&amp;", '<'=>"&lt;", '>'=>"&gt;", '"'=>"&quot;", '\''=>"&#39;")[m[1]])
end

function parse_arguments()
    port = 8000
    directory = pwd()

    for (i, arg) in enumerate(ARGS)
        if arg in ["-p", "--port"] && i < length(ARGS)
            port = parse(Int, ARGS[i+1])
        elseif arg in ["-d", "--directory"] && i < length(ARGS)
            directory = ARGS[i+1]
        end
    end

    return port, directory
end

function run_server(port::Int, directory::String)
    handler = CustomHTTPRequestHandler(directory)
    HTTP.serve(req -> handle_request(handler, req), "0.0.0.0", port)
end

function handle_request(handler::CustomHTTPRequestHandler, req::HTTP.Request)
    uri = HTTP.URI(req.target).path
    if uri == "/" || uri == "/index.html"
        check_and_generate_report(handler)
        return HTTP.Response(200, ["Content-Type" => "text/html"], body="Hello, World!")
    elseif endswith(uri, ".txt")
        return serve_text_file(handler, uri)
    else
        filename = uri[2:end]
        return serve_file(handler, filename)
    end
end

port, directory = parse_arguments()
run_server(port, directory)
