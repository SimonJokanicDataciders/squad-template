---
name: "python-ml"
matches: ["machine learning", "ml", "data science", "scikit", "sklearn", "pandas", "streamlit", "jupyter", "notebook"]
version: "1.6"
updated: "2026-03-30"
status: "beta"
---

# Python ML/Data Science — Seed

## Critical Rules (LLM MUST follow these)
1. Separate code into clear stages: data loading, preprocessing, feature engineering, model training, evaluation, and serialization.
2. Always split data into train/test **before** any preprocessing or feature engineering to prevent data leakage.
3. Use `sklearn.pipeline.Pipeline` (or `ColumnTransformer`) to bundle preprocessing with the model — never transform raw arrays manually.
4. Set `random_state` on every estimator, `train_test_split`, and shuffle operation for reproducibility.
5. Save trained models with `joblib.dump` (not `pickle`) and version the artifact with metadata (params, metrics, date).
6. Use Streamlit for quick interactive dashboards; keep Streamlit scripts in a dedicated `app/` directory.
7. Never call `fit_transform` on test/validation data — call `transform` only after fitting on training data.
8. Use relative or config-driven paths for data files — never hardcode absolute paths.

## Golden Example
```python
import joblib
import pandas as pd
from datetime import date
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

RANDOM_STATE = 42

# --- Data loading ---
df = pd.read_csv("data/customers.csv")
X = df.drop(columns=["churned"])
y = df["churned"]

# --- Train/test split BEFORE any preprocessing ---
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
)

# --- Preprocessing via Pipeline ---
numeric_features = ["age", "monthly_spend", "tenure_months"]
categorical_features = ["plan_type", "region"]

preprocessor = ColumnTransformer(
    transformers=[
        ("num", StandardScaler(), numeric_features),
        ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features),
    ]
)

pipeline = Pipeline([
    ("preprocessor", preprocessor),
    ("classifier", RandomForestClassifier(
        n_estimators=200, max_depth=10, random_state=RANDOM_STATE
    )),
])

# --- Training ---
pipeline.fit(X_train, y_train)

# --- Evaluation (transform only, no fit) ---
y_pred = pipeline.predict(X_test)
report = classification_report(y_test, y_pred, output_dict=True)
print(classification_report(y_test, y_pred))

# --- Serialization with metadata ---
artifact = {
    "model": pipeline,
    "metrics": report,
    "features": numeric_features + categorical_features,
    "created": str(date.today()),
    "random_state": RANDOM_STATE,
}
joblib.dump(artifact, "models/churn_model_v1.joblib")
```

## Common LLM Mistakes
- **Data leakage — preprocessing before split.** Calling `fit_transform` on the entire dataset before splitting lets test statistics leak into training. Always split first, then fit on train only.
- **Not setting `random_state`.** Omitting the seed makes results non-reproducible. Every estimator, split, and shuffle must use an explicit seed.
- **Calling `fit_transform` on test data.** Test data must only be `transform`-ed using parameters learned from the training set. `fit_transform` on test data recomputes statistics and breaks the evaluation.
- **Hardcoded absolute paths.** Paths like `/Users/alice/data/file.csv` break on every other machine. Use relative paths or a config/env variable.
- **No model versioning.** Saving the model without metrics, parameters, or a timestamp makes it impossible to compare runs or reproduce results later.
- **Manual preprocessing outside a Pipeline.** Applying `StandardScaler` in a separate step and then passing arrays to the model creates a two-object dependency that is easy to misalign at inference time. Use `sklearn.pipeline.Pipeline` to bundle everything.
