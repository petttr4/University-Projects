
# Movie Review Sentiment Analysis (NLP & Machine Learning)

Αυτό το repository περιέχει μια ολοκληρωμένη μελέτη **Ανάλυσης Συναισθήματος (Sentiment Analysis)** σε κριτικές ταινιών (Movie Review Polarity Dataset - 2,000 κείμενα) με τη χρήση τεχνικών Επεξεργασίας Φυσικής Γλώσσας (NLP) και Μηχανικής Μάθησης (Machine Learning). 

Η υλοποίηση έγινε τόσο σε περιβάλλον **Python (Google Colab / Scikit-Learn)** όσο και σε **RapidMiner**.

## Περιεχόμενο Εργασίας

Η εργασία χωρίζεται σε δύο βασικά σκέλη:

### 1. Baseline Μοντέλα & Αναπαραστάσεις (Μέρος Α)
* **Προεπεξεργασία:** Tokenization, Lowercasing, Stopword Removal και Porter Stemming.
* **Διανυσματοποίηση (Vectorization):**
  * Term Frequency (CountVectorizer)
  * TF-IDF (TfidfVectorizer)
  * Binary Vectorization
  * Word2Vec (Mean-Pooling με Gensim)
* **Ταξινομητές:** Multinomial Naive Bayes, Bernoulli Naive Bayes.
* **Αξιολόγηση:** Stratified 5-Fold Cross-Validation με μετρικές Accuracy, Precision, Recall, F1-Score και Confusion Matrix.

### 2. Προηγμένες Τεχνικές NLP (Μέρος Β)
* **Διαχείριση Άρνησης (Negation Handling):** Προσθήκη prefix `NOT_` σε λέξεις που ακολουθούν αρνητικούς όρους (π.χ. *not, don't*).
* **POS Weighting:** Ενίσχυση βάρους (x2) σε επιθετικά και επιρρήματα (Adjectives & Adverbs).
* **Sentence Position Weighting:** Ενίσχυση βάρους (x2) σε όρους που εμφανίζονται στην 1η ή την τελευταία πρόταση του κειμένου.

---

## Κύρια Αποτελέσματα

* **Καλύτερη Επίδοση:** Το μοντέλο **Boolean Multinomial Naive Bayes** πέτυχε το υψηλότερο F1-Score (**~82.35%**) με τη χρήση Stemming και Negation Handling.
* **Word2Vec (Mean Pooling):** Έδωσε χαμηλότερη ακρίβεια (~57.45%), αναδεικνύοντας τους περιορισμούς του απλού μέσου όρου διανυσμάτων χωρίς ακολουθιακή πληροφορία σε Naive Bayes.

---

## Τεχνολογίες & Βιβλιοθήκες

* **Python 3.12+**
* **NLTK** (Tokenization, Stopwords, POS Tagging, Porter Stemmer)
* **Scikit-Learn** (Vectorizers, Naive Bayes models, StratifiedKFold, Metrics)
* **Gensim** (Word2Vec)
* **Pandas & NumPy** (Διαχείριση δεδομένων)
* **RapidMiner 12.0** (Workflow XML processes)

---

## Δομή Αρχείων

```text
├── sentiment_analysis.ipynb    # Το κύριο Google Colab Notebook με τον Python κώδικα
├── process_baseline.rmp        # RapidMiner Process (Baseline Naive Bayes)
├── process_stemming.rmp        # RapidMiner Process (Naive Bayes + Porter Stemmer)
└── README.md                   # Περιγραφή του repository
