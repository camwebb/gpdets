#!/usr/bin/gawk -f

BEGIN{

  # check data directory
  while(("/usr/bin/du -sk data" | getline)>0)
    datasize = $1
  
  if (datasize > 100000)
    fail("Data directory full")
  
  # sending data?
  if (ENVIRON["CONTENT_TYPE"] ~ /form-data/)
    read_file()
  else
    default_page()
  
  print "Content-Type: text/html\n"
  if (system("./bin/gpreport " TEMPDIR "/" FILE " 2> " TEMPDIR "/error")) {
    print "<html><pre>"
    system("cat " TEMPDIR "/error")
    print "</pre></html>"
  }
}


function fail(msg) {
  print "Content-Type: text/plain\n"
  print msg
  exit 1
}

function read_file(   ct, total) {

  # Temporary directory
  # "mktemp -d" | getline TEMPDIR ;
  TEMPDIR = "data"
  FILE = strftime("%Y%m%d_%H%H.xlsx")
  
  RS = ORS = "\r\n"
  while((getline < "/dev/stdin")>0) {
    if ($0 ~ /^[Cc]ontent-[Tt]ype/)
      ct = $2
    # Ignore boundary ("^----" is not required but generally used; WebKit
    #   starts boundary with ------WebKit...), other content lines
    #   (see rfc1521; possibly a "Content-Transfer-Encoding"), and blank lines
    # To Do: read Content-type Header from ENV, parse out form boundary and use
    if (($0 ~ /^----/) ||        \
        ($0 ~ /^[Cc]ontent-/) || \
        ($0 == ""))
      { }
    else {
      total += length($0)
      if (total < 1000000)
        print $0 > TEMPDIR "/" FILE
      else
        fail("File size too big!")
    }
  }
  
  if (ct !~ /openxmlformats-officedocument\.spreadsheet/)
    fail("Your MIME type (" ct ") incorrect")
  #else
  #  print "Content-Type: text/plain\n\nOK. At: "TEMPDIR "/" FILE
}

function default_page() {
  print "Content-Type: text/html\n"
  print "<!DOCTYPE html><html>                                          \
    <head>                                                              \
    <title>Upload XLSX file for GPDets</title>                          \
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/> \
    <style>                                                             \
       body  { font-size: 14px; font-family: Arial, Helvetica, sans-serif; } \
       .main { max-width: 1200px; padding-top: 30px;                    \
               margin-left: auto; margin-right: auto; }                 \
    </style>                                                            \
    </head>                                                             \
    <body>                                                              \
    <div class=\"main\">                                                \
    <h1>Upload XLSX file for GPDets</h1>                                \
    <form enctype=\"multipart/form-data\" action=\"do\" method=\"post\"> \
      <p>                                                               \
        Select Excel file: <input type=\"file\" name=\"xlsx\" /><br/><br/> \
        <input type=\"submit\" value=\"Submit\" />                      \
      </p>                                                              \
    </form>                                                             \
    <p>(<a href=\"test/gpdets.xlsx\">demo file</a>)</p>                 \
    <p style=\"padding-top: 30px;\"><a href=\"methods.html\">"          \
      "More information</a></p>                                         \
    </div>                                                              \
    </body>                                                             \
    </html>"
  exit 0
}
  
