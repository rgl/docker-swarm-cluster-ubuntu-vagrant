package main

import (
	"flag"
	"fmt"
	"html/template"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
)

var indexTemplate = template.Must(template.New("Index").Parse(`<!DOCTYPE html>
<html>
<head>
<title>Hello World</title>
<style>
body {
	font-family: DejaVu Sans,Verdana,Geneva,sans-serif;
	font-size: 13px;
	background: #ececec;
}
</style>
</head>
<body>
	<table>
		<caption>Properties</caption>
		<tbody>
			<tr><th>Pid</th><td>{{.Pid}}</td></tr>
			<tr><th>Request</th><td>{{.Request}}</td></tr>
			<tr><th>Client Address</th><td>{{.ClientAddress}}</td></tr>
			<tr><th>Server Address</th><td>{{.ServerAddress}}</td></tr>
			<tr><th>Hostname</th><td>{{.Hostname}}</td></tr>
			<tr><th>Os</th><td>{{.Os}}</td></tr>
			<tr><th>Architecture</th><td>{{.Architecture}}</td></tr>
			<tr><th>Runtime</th><td>{{.Runtime}}</td></tr>
		</tbody>
	</table>
	<table>
		<caption>Environment Variables</caption>
		<thead>
			<tr>
				<th>Name</th>
				<th>Value</th>
			</tr>
		</thead>
		<tbody>
			{{- range .Environment}}
			<tr>
				<td>{{.Name}}</td>
				<td>{{.Value}}</td>
			</tr>
			{{- end}}
		</tbody>
	</table>
	<table>
		<caption>Secrets</caption>
		<thead>
			<tr>
				<th>Name</th>
				<th>Value</th>
			</tr>
		</thead>
		<tbody>
			{{- range .Secrets}}
			<tr>
				<td>{{.Name}}</td>
				<td><pre>{{.Value}}</pre></td>
			</tr>
			{{- end}}
		</tbody>
	</table>
	<table>
		<caption>Configs</caption>
		<thead>
			<tr>
				<th>Name</th>
				<th>Value</th>
			</tr>
		</thead>
		<tbody>
			{{- range .Configs}}
			<tr>
				<td>{{.Name}}</td>
				<td><pre>{{.Value}}</pre></td>
			</tr>
			{{- end}}
		</tbody>
	</table>
</body>
</html>
`))

type nameValuePair struct {
	Name  string
	Value string
}

type indexData struct {
	Pid           int
	Request       string
	ClientAddress string
	ServerAddress string
	Hostname      string
	Os            string
	Architecture  string
	Runtime       string
	Environment   []nameValuePair
	Secrets       []nameValuePair
	Configs       []nameValuePair
}

type nameValuePairs []nameValuePair

func (a nameValuePairs) Len() int           { return len(a) }
func (a nameValuePairs) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a nameValuePairs) Less(i, j int) bool { return a[i].Name < a[j].Name }

func main() {
	log.SetFlags(0)

	var listenAddress = flag.String("listen", ":8000", "Listen address.")

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("%s %s%s\n", r.Method, r.Host, r.URL)

		if r.URL.Path != "/" {
			http.Error(w, "Not Found", http.StatusNotFound)
			return
		}

		hostname, err := os.Hostname()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/html")

		environment := make([]nameValuePair, 0)
		for _, v := range os.Environ() {
			parts := strings.SplitN(v, "=", 2)
			name := parts[0]
			value := parts[1]
			environment = append(environment, nameValuePair{name, value})
		}
		sort.Sort(nameValuePairs(environment))

		secrets := make([]nameValuePair, 0)
		secretFiles, _ := filepath.Glob("/run/secrets/*")
		for _, v := range secretFiles {
			name := filepath.Base(v)
			value, _ := ioutil.ReadFile(v)
			secrets = append(secrets, nameValuePair{name, string(value)})
		}
		sort.Sort(nameValuePairs(secrets))

		configs := make([]nameValuePair, 0)
		configFiles, _ := filepath.Glob("/run/configs/*")
		for _, v := range configFiles {
			name := filepath.Base(v)
			value, _ := ioutil.ReadFile(v)
			configs = append(configs, nameValuePair{name, string(value)})
		}
		sort.Sort(nameValuePairs(configs))

		err = indexTemplate.ExecuteTemplate(w, "Index", indexData{
			Pid:           os.Getpid(),
			Request:       fmt.Sprintf("%s %s%s", r.Method, r.Host, r.URL),
			ClientAddress: r.RemoteAddr,
			ServerAddress: r.Context().Value(http.LocalAddrContextKey).(net.Addr).String(),
			Hostname:      hostname,
			Os:            runtime.GOOS,
			Architecture:  runtime.GOARCH,
			Runtime:       runtime.Version(),
			Environment:   environment,
			Secrets:       secrets,
			Configs:       configs,
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	})

	fmt.Printf("Listening at http://%s\n", *listenAddress)

	err := http.ListenAndServe(*listenAddress, nil)
	if err != nil {
		log.Fatalf("Failed to ListenAndServe: %v", err)
	}
}
