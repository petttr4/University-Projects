
# Big Data - Homework 2

Ατομική εργασία στο πλαίσιο του μαθήματος Big Data, με αντικείμενο την ανάλυση δεδομένων πελατών τηλεπικοινωνιών (telecom_churn_10k.csv) και την πρόβλεψη αποχώρησης πελατών (churn) με χρήση Apache Spark.

## Περιγραφή

Η εργασία καλύπτει ολόκληρη τη ροή επεξεργασίας δεδομένων: από τον καθαρισμό και εμπλουτισμό ενός dataset, μέχρι την ανάλυση με SQL ερωτήματα και την εκπαίδευση μοντέλου μηχανικής μάθησης για πρόβλεψη.

### Θέματα που καλύπτονται
1. **Φόρτωση, έλεγχος και καθαρισμός δεδομένων** – Εντοπισμός και διαχείριση ελλιπών τιμών (dropna για CHURN, mean imputation για AGE/TENURE_MONTHS, υπολογισμός για TOTAL_CHARGES), περιγραφική στατιστική ανάλυση, και feature engineering (NUM_SERVICES, AVG_CHARGE_PER_MONTH, IS_LONG_TENURE)
2. **Ανάλυση με Spark SQL** – Ερωτήματα πάνω στο καθαρισμένο dataset: churn ανά τύπο συμβολαίου, ανά πλήθος υπηρεσιών, σε σχέση με μηνιαία χρέωση, και γεωγραφική ανάλυση ανά χώρα
3. **Spark ML Pipeline** – Μοντέλο DecisionTreeRegressor για πρόβλεψη μηνιαίας χρέωσης (MONTHLY_CHARGES) με χρήση StringIndexer και VectorAssembler, αξιολόγηση με RMSE (8.01) και R² (0.50)

## Περιεχόμενα φακέλου
- `report2-ics23085.pdf` – Πλήρης αναφορά της εργασίας με αποτελέσματα και σχολιασμό
- `Big_Data_HW2_.ipynb` – Jupyter/Colab notebook με όλη την υλοποίηση
- `Διάγραμμα_1.png` – Actual vs Predicted Monthly Charges (αποτέλεσμα Decision Tree)
- `Διάγραμμα_2.png` – Μέση μηνιαία χρέωση ανά κατάσταση churn

## Τεχνολογίες
- Python, PySpark (DataFrame API, Spark SQL, Spark ML)
- Pandas, Matplotlib
- Google Colab

## Μάθημα
Big Data
