from flask import Flask,request,render_template
import psycopg2

app = Flask(__name__)

def get_conn():
    return psycopg2.connect(
        dbname="postgres"  ,
        user="postgres",
        password="petroula",
        host="localhost"  ,
        port="5432"
    )

@app.route('/')
def index():
    return render_template('search.html')

@app.route('/search')
def search():
    query = request.args.get('q')
    #διαβάζουμε τις νέες παραμέτρους με προεπιλεγμένες τιμές
    operator = request.args.get('operator', '&')  # & (AND) ή | (OR)
    scope = request.args.get('scope', 'both_or')  # both_or, both_and, title, abstract

    if not query:
        return render_template('results.html', total=0, rows=[])

    #δυναμική κατασκευή του ts_query
    ts_query = query.replace(" ", f" {operator} ")
    
    #κατασκευή της WHERE clause και της λίστας παραμέτρων
    where_parts = []
    execution_params = [ts_query]
    
    #προσθήκη των WHERE συνθηκών και τις παραμέτρους
    if scope == 'title':
        where_parts.append("title_tsv @@ to_tsquery('english', %s)")
        execution_params.append(ts_query )
        where_clause = where_parts[0]
        
    elif scope == 'abstract':
        where_parts.append("abstract_tsv @@ to_tsquery('english',%s)")
        execution_params.append(ts_query)
        where_clause = where_parts[0]
        
    elif scope == 'both_and':
        where_parts.append("title_tsv @@ to_tsquery('english', %s)")
        where_parts.append("abstract_tsv @@ to_tsquery('english',%s)")
        execution_params.append(ts_query )
        execution_params.append(ts_query)
        where_clause = " AND ".join(where_parts)
        
    else:#προεπιλογή:'both_or' (Τίτλος Η Περίληψη)
        where_parts.append("title_tsv @@ to_tsquery('english', %s)")
        where_parts.append("abstract_tsv @@ to_tsquery('english', %s)")
        execution_params.append(ts_query)
        execution_params.append(ts_query)
        where_clause = " OR ".join(where_parts )

   
    #το %s στο ts_rank_cd παίρνει την πρώτη παράμετρο
    sql = f"""
        SELECT id, title,
        ts_rank_cd(title_tsv || abstract_tsv, to_tsquery('english', %s)) AS rank
        FROM docs
        WHERE {where_clause}
        ORDER BY rank DESC;
    """

    conn = get_conn()
    cur = conn.cursor()
    cur.execute(sql, tuple(execution_params))
    rows = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('results.html',total=len(rows),rows=rows)
    
if __name__ == "__main__":
    app.run(debug=True)
