from flask import Flask, request, render_template, redirect, url_for ,send_from_directory
import subprocess
app = Flask(__name__, template_folder="HTML")
app.config['UPLOAD_FOLDER'] = 'UPLOADS_FOLDER'
app.config['static'] = 'static'
@app.route('/')
def home():
    return render_template("Home.html")
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return render_template("Home.html", message="No file uploaded"), 400
    file = request.files['file']
    if (file.filename[-4:] != ".log"):
        return render_template("Home.html", message="please upload a log file"), 400
    file_path = "givenfile.log" 
    file.save(file_path)
    try:
        subprocess.run(['bash', 'csv.sh', file_path], check=True, capture_output=True, text=True) #generates output.csv,error.csv,notics.csv
        return redirect(url_for("download_page", name="all")) #redirect to download-page
    except subprocess.CalledProcessError as e:
        return render_template("Home.html", message="Uploaded file is not a valid log format."), 400
@app.route('/download00/<name>')
def download_file0(name):
    return send_from_directory(app.config["UPLOAD_FOLDER"], name, as_attachment = True)
@app.route('/download000/<name>')
def download_file00(name):
    return send_from_directory(app.config["static"], name, as_attachment = True)
@app.route('/download-page/<name>')
def download_page(name): #this is for table filter
    list = request.args.getlist('event')
    list1 = request.args.getlist('event1')
    list2 = request.args.getlist('event2')
    filname="output.csv"
    if ((list1 != [''] or list2 != ['']) and (list1 != [] or list2 != [])):
        if (list2 == [] or list2 == ['']): # if start date is given and end date is not given, then make end date = "empty"
            list2[0]="empty"
        filname="time_filter.csv" #set the filname to time_filter.csv which has its data with time stamp in the range of time given(obtained after running bash script filter_time.sh).
        try:
            subprocess.run(['bash', 'filter_time.sh', list1[0], list2[0],"output.csv","table"], check=True, capture_output=True, text=True) # passing the argument as table to tell the bash script that it is for the table.
        except subprocess.CalledProcessError as e:
            return render_template("download.html", message1="Either Invalid Date Format or end date is earlier than start date"), 400 
        usr="0" 
    else:
        filname="output.csv" # if the user not selected time filter, then set silname th output.csv
        usr="0"
    if(name=="all"):
        usr="0"
    elif(name=="notice"):
        usr="1"
    elif(name=="error"):
        usr="2"
    content = ""
    mess = ""
    table = [['one','two','three','four','five','six']]
    count = 0
    with open(f"UPLOADS_FOLDER/{filname}","r") as file: 
        count=0
        file.readline()
        for line in file:
            content += line 
            lines = line.strip()
            words = lines.split(',')
            if ((len(words) > 3) and ((words[3] in list) or (len(list)==0))): # add all the lines that matches into the list table.
                if(words[1]=="notice" and (usr=="0" or usr=="1")):
                    count+=1
                    table.append([count,words[0],words[1],words[2],words[3],words[4]])
                elif(words[1]=="error" and (usr=="0" or usr=="2")):
                    count+=1
                    table.append([count,words[0],words[1],words[2],words[3],words[4]])
                content += "<br>"
    table.pop(0)
    with open('UPLOADS_FOLDER/table_filter.csv', 'w') as file:
        file.write("Timestamp,Level,Component,EventId,Event Template" + '\n')
        for row in table:
            file.write(str(row[1]) + ',' + str(row[2]) + ',' + str(row[3]) + ',' + str(row[4])+ ',' + str(row[5]) + '\n') # write the data into table_filter.csv to store the data of table filter
    html_table = "<table>\n"
    html_table+="<thead><tr><th>S.No</th><th>Timestamp</th><th>Level</th><th>Component</th><th>EventId</th><th>Event Template</th></thead>"
    for row in table:
        html_table += "  <tr>\n"
        for cell in row:
            html_table += f"    <td>{cell}</td>\n"
        html_table += "  </tr>\n"
    html_table += "</table>"                                                                                                                            
    return render_template("download.html",context=content ,data = html_table) 
@app.route('/plot_filter1', methods=['POST'])
def load_file():
    arg1=request.form['sttime'].rstrip()
    arg2=request.form['entime'].rstrip()
    arg3=request.form.get('include')   
    if (arg2=="" and arg1 != ""): 
        arg2="empty"
    if(arg1=="" and arg2==""):
        arg1="empty"
        arg2="empty"
    if (arg3=="yes"): file="table_filter.csv"
    else: file="output.csv"
    try:
        subprocess.run(['bash', 'filter_time.sh',arg1,arg2,file,"u"], check=True, capture_output=True, text=True) # giving argument u (you can give anythiing except table) to tell the bash script it is for plotting
        return render_template("Plot.html",mess1="")
    except subprocess.CalledProcessError as e:
            return render_template("download.html", message2="Either Invalid Date Format or end date is earlier than start date"), 400
@app.route('/plot_filter2', methods=['POST'])
def load1_file():
    arg1=request.form['sttime'].rstrip()
    arg2=request.form['entime'].rstrip()
    file="output.csv"
    if (arg2 == "" and arg1 !=""):
        arg2="empty"
    if(arg1=="" and arg2==""):
        arg1="empty"
        arg2="empty"
    try:
        subprocess.run(['bash', 'filter_time.sh',arg1,arg2,file,"u"], check=True, capture_output=True, text=True)
        return render_template("Plot.html",mess1="")
    except subprocess.CalledProcessError as e:
        return render_template("Plot.html", message2="Either Invalid Date Format or end date is earlier than start date"), 400 # display the error message
@app.route('/plot',methods=['POST'])
def plot_filter():
    plot=request.form.get('plot')
    return render_template("Plot.html",mess1=plot)
@app.route('/tabl', methods=['POST'])
def table_filter():
    selected_level = request.form.get('level')
    selected_list = request.form.getlist('event')
    arg11=request.form['time1'].rstrip()
    arg22=request.form['time2'].rstrip()
    return redirect(url_for("download_page", name=selected_level,**{"event": selected_list,"event1":arg11,"event2":arg22}))
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
