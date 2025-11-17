# AI/ML Pipeline Design for Follower Analysis and Ad Generation

## Executive Summary

This document outlines a comprehensive AI/ML pipeline for analyzing social media followers and generating personalized advertisements. The system leverages state-of-the-art NLP models, vector databases, and modern MLOps practices to deliver scalable, cost-effective solutions.

---

## Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [ML Model Selection](#ml-model-selection)
3. [Data Preprocessing Pipeline](#data-preprocessing-pipeline)
4. [Feature Engineering](#feature-engineering)
5. [Training vs Inference Architecture](#training-vs-inference-architecture)
6. [Model Serving Infrastructure](#model-serving-infrastructure)
7. [API Integrations](#api-integrations)
8. [Vector Databases](#vector-databases)
9. [Real-time vs Batch Processing](#real-time-vs-batch-processing)
10. [Model Versioning and A/B Testing](#model-versioning-and-ab-testing)
11. [Cost Optimization](#cost-optimization)
12. [Fallback Mechanisms](#fallback-mechanisms)
13. [Quality Assurance](#quality-assurance)
14. [Technology Stack](#technology-stack)

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Data Ingestion Layer                          │
│  Social Media APIs → Data Validation → Raw Data Storage (S3)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 Data Preprocessing Pipeline                      │
│  Text Cleaning → Deduplication → Normalization → Feature Store  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    ML Processing Layer                           │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐         │
│  │  Embedding  │  │  Sentiment   │  │  Topic         │         │
│  │  Generation │  │  Analysis    │  │  Modeling      │         │
│  └─────────────┘  └──────────────┘  └────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              Clustering & Segmentation Layer                     │
│  Vector DB Query → K-Means/HDBSCAN → Persona Generation         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  Ad Generation Layer                             │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐         │
│  │  Copy Gen   │  │  Image Gen   │  │  A/B Testing   │         │
│  │  (LLM)      │  │  (Diffusion) │  │  & Ranking     │         │
│  └─────────────┘  └──────────────┘  └────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              Serving & Monitoring Layer                          │
│  API Gateway → Cache → CDN → Analytics → Feedback Loop          │
└─────────────────────────────────────────────────────────────────┘
```

---

## ML Model Selection

### 1. Follower Interest Analysis

**Primary Model: Sentence-BERT (all-MiniLM-L6-v2)**
- **Library**: `sentence-transformers`
- **Why**: Fast, efficient embeddings (384 dimensions), good for semantic similarity
- **Use Case**: Convert posts, comments, likes into embeddings
- **Alternative**: OpenAI `text-embedding-3-small` for higher quality (512-1536 dims)

```python
# Primary (Self-hosted)
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')

# Alternative (API)
import openai
embeddings = openai.Embedding.create(
    input=text,
    model="text-embedding-3-small"
)
```

**Topic Modeling: BERTopic**
- **Library**: `bertopic`
- **Why**: State-of-the-art topic modeling with BERT embeddings
- **Components**: UMAP for dimensionality reduction, HDBSCAN for clustering

```python
from bertopic import BERTopic
from umap import UMAP
from hdbscan import HDBSCAN

umap_model = UMAP(n_neighbors=15, n_components=5, metric='cosine')
hdbscan_model = HDBSCAN(min_cluster_size=10, metric='euclidean')
topic_model = BERTopic(umap_model=umap_model, hdbscan_model=hdbscan_model)
```

### 2. Natural Language Processing

**Text Analysis: spaCy**
- **Library**: `spacy` (en_core_web_trf - transformer-based)
- **Why**: Fast, accurate NER, POS tagging, dependency parsing
- **Use Case**: Extract entities, keywords, linguistic features

```python
import spacy
nlp = spacy.load("en_core_web_trf")
```

**Alternative for Scale: spaCy en_core_web_sm**
- **Why**: 10x faster, 95% accuracy for most tasks
- **Use Case**: Real-time processing

### 3. Sentiment Analysis

**Primary: VADER (Valence Aware Dictionary and sEntiment Reasoner)**
- **Library**: `vaderSentiment`
- **Why**: Fast, no training needed, excellent for social media
- **Latency**: <1ms per text

```python
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
analyzer = SentimentIntensityAnalyzer()
scores = analyzer.polarity_scores(text)
```

**Secondary: RoBERTa-based Sentiment**
- **Model**: `cardiffnlp/twitter-roberta-base-sentiment-latest`
- **Library**: `transformers`
- **Why**: Higher accuracy, context-aware
- **Use Case**: Fallback or quality validation

```python
from transformers import AutoModelForSequenceClassification, AutoTokenizer
model = AutoModelForSequenceClassification.from_pretrained(
    "cardiffnlp/twitter-roberta-base-sentiment-latest"
)
tokenizer = AutoTokenizer.from_pretrained(
    "cardiffnlp/twitter-roberta-base-sentiment-latest"
)
```

### 4. Customer Segmentation

**Algorithm: HDBSCAN (Hierarchical DBSCAN)**
- **Library**: `hdbscan`
- **Why**: No need to specify number of clusters, handles noise, hierarchical
- **Alternative**: K-Means for fixed cluster counts

```python
import hdbscan

clusterer = hdbscan.HDBSCAN(
    min_cluster_size=50,
    min_samples=10,
    metric='euclidean',
    cluster_selection_method='eom'
)
```

**Dimensionality Reduction: UMAP**
- **Library**: `umap-learn`
- **Why**: Preserves local and global structure better than t-SNE
- **Use Case**: Reduce embeddings before clustering

### 5. Persona Generation

**Model: Claude 3.5 Sonnet (Anthropic)**
- **API**: `anthropic`
- **Why**: Excellent at structured output, reasoning, and creative writing
- **Use Case**: Generate detailed personas from cluster statistics

```python
import anthropic

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=2048,
    messages=[{"role": "user", "content": prompt}]
)
```

**Alternative: GPT-4o**
- **API**: `openai`
- **Why**: JSON mode, function calling
- **Use Case**: Structured persona output

### 6. Personalized Ad Copy Generation

**Primary: Claude 3.5 Sonnet**
- **Why**: Superior creative writing, brand voice consistency
- **Batch Processing**: Use Message Batches API (50% cost reduction)

```python
# Single request
response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    system="You are an expert ad copywriter...",
    messages=[{"role": "user", "content": persona_prompt}]
)

# Batch processing
batch = client.messages.batches.create(
    requests=[
        {"custom_id": f"ad_{i}", "params": {...}}
        for i in range(1000)
    ]
)
```

**Secondary: GPT-4o-mini**
- **Why**: Cost-effective ($0.15/1M input tokens)
- **Use Case**: High-volume, shorter copy

**Tertiary: Llama 3.1 70B (Self-hosted)**
- **Library**: `vllm`
- **Why**: No API costs, full control
- **Infrastructure**: A100 GPU (80GB)

### 7. Ad Image Generation

**Primary: DALL-E 3**
- **API**: `openai`
- **Why**: High quality, good prompt following, HD quality
- **Cost**: $0.040-$0.080 per image

```python
response = openai.images.generate(
    model="dall-e-3",
    prompt=image_prompt,
    size="1024x1024",
    quality="hd",
    n=1
)
```

**Secondary: Stable Diffusion XL**
- **Library**: `diffusers` (HuggingFace)
- **Why**: Self-hosted, customizable, lower cost at scale
- **Infrastructure**: A100 GPU

```python
from diffusers import StableDiffusionXLPipeline
import torch

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16
)
pipe = pipe.to("cuda")
image = pipe(prompt=prompt).images[0]
```

**Tertiary: Midjourney API**
- **Why**: Highest quality for brand imagery
- **Use Case**: Premium campaigns

### 8. A/B Testing and Optimization

**Multi-Armed Bandit: Thompson Sampling**
- **Library**: Custom implementation with `scipy`
- **Why**: Better than traditional A/B testing, continuous optimization

```python
from scipy.stats import beta
import numpy as np

class ThompsonSampling:
    def __init__(self, n_variants):
        self.alpha = np.ones(n_variants)
        self.beta = np.ones(n_variants)
    
    def select_variant(self):
        samples = [np.random.beta(a, b) for a, b in zip(self.alpha, self.beta)]
        return np.argmax(samples)
    
    def update(self, variant, reward):
        if reward:
            self.alpha[variant] += 1
        else:
            self.beta[variant] += 1
```

**Ranking Model: LambdaMART**
- **Library**: `lightgbm`
- **Why**: State-of-the-art learning-to-rank
- **Use Case**: Rank ad variants for each user

---

## Data Preprocessing Pipeline

### Architecture

```python
# Pipeline using Apache Beam / Prefect
from prefect import flow, task
import pandas as pd
import re
from typing import Dict, List

@task
def ingest_social_data(user_id: str) -> Dict:
    """Fetch data from social media APIs"""
    data = {
        'posts': fetch_posts(user_id),
        'comments': fetch_comments(user_id),
        'likes': fetch_likes(user_id),
        'shares': fetch_shares(user_id)
    }
    return data

@task
def clean_text(text: str) -> str:
    """Clean and normalize text"""
    # Remove URLs
    text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
    # Remove mentions
    text = re.sub(r'@\w+', '', text)
    # Remove hashtags (optional - keep for topic modeling)
    # text = re.sub(r'#\w+', '', text)
    # Remove special characters
    text = re.sub(r'[^\w\s#]', '', text)
    # Normalize whitespace
    text = ' '.join(text.split())
    return text.lower().strip()

@task
def deduplicate(df: pd.DataFrame) -> pd.DataFrame:
    """Remove duplicate content"""
    # Exact duplicates
    df = df.drop_duplicates(subset=['text'])
    # Near duplicates (using MinHash LSH)
    from datasketch import MinHash, MinHashLSH
    
    lsh = MinHashLSH(threshold=0.9, num_perm=128)
    minhashes = {}
    
    for idx, text in enumerate(df['text']):
        m = MinHash(num_perm=128)
        for word in text.split():
            m.update(word.encode('utf8'))
        lsh.insert(idx, m)
        minhashes[idx] = m
    
    # Keep only first occurrence of near-duplicates
    to_remove = set()
    for idx in range(len(df)):
        if idx not in to_remove:
            duplicates = lsh.query(minhashes[idx])
            to_remove.update(d for d in duplicates if d > idx)
    
    return df.drop(index=to_remove).reset_index(drop=True)

@task
def validate_data(df: pd.DataFrame) -> pd.DataFrame:
    """Validate and filter data quality"""
    # Remove empty or too short texts
    df = df[df['text'].str.len() > 10]
    # Remove non-English content (optional)
    from langdetect import detect
    df['lang'] = df['text'].apply(lambda x: detect(x) if len(x) > 20 else 'unknown')
    df = df[df['lang'] == 'en']
    # Remove spam/bot content
    df = df[~df['text'].str.contains(r'(follow back|f4f|dm for promo)', case=False, na=False)]
    return df

@task
def enrich_metadata(df: pd.DataFrame) -> pd.DataFrame:
    """Add temporal and engagement metadata"""
    df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
    df['day_of_week'] = pd.to_datetime(df['timestamp']).dt.dayofweek
    df['engagement_rate'] = (df['likes'] + df['comments'] + df['shares']) / df['followers']
    return df

@flow
def preprocessing_pipeline(user_id: str):
    """Main preprocessing pipeline"""
    # Ingest
    raw_data = ingest_social_data(user_id)
    
    # Combine all text sources
    df = combine_data_sources(raw_data)
    
    # Clean
    df['text_clean'] = df['text'].apply(clean_text)
    
    # Deduplicate
    df = deduplicate(df)
    
    # Validate
    df = validate_data(df)
    
    # Enrich
    df = enrich_metadata(df)
    
    # Store in feature store
    store_features(df)
    
    return df
```

### Data Quality Checks

```python
import great_expectations as ge

def validate_pipeline_output(df: pd.DataFrame):
    """Validate data quality using Great Expectations"""
    gdf = ge.from_pandas(df)
    
    # Expectations
    gdf.expect_column_values_to_not_be_null('text_clean')
    gdf.expect_column_values_to_be_between('engagement_rate', 0, 1)
    gdf.expect_column_values_to_be_in_set('lang', ['en'])
    gdf.expect_column_value_lengths_to_be_between('text_clean', 10, 10000)
    
    validation_result = gdf.validate()
    
    if not validation_result['success']:
        raise ValueError("Data validation failed")
    
    return validation_result
```

---

## Feature Engineering

### Text Features

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from collections import Counter
import numpy as np

class FeatureEngineer:
    def __init__(self):
        self.tfidf = TfidfVectorizer(max_features=1000, ngram_range=(1, 2))
        
    def extract_text_features(self, texts: List[str]) -> Dict:
        """Extract comprehensive text features"""
        features = {}
        
        # 1. Statistical features
        features['avg_word_count'] = np.mean([len(t.split()) for t in texts])
        features['avg_char_count'] = np.mean([len(t) for t in texts])
        features['vocabulary_diversity'] = len(set(' '.join(texts).split())) / sum(len(t.split()) for t in texts)
        
        # 2. TF-IDF features
        features['tfidf_matrix'] = self.tfidf.fit_transform(texts)
        features['top_keywords'] = self.get_top_keywords(features['tfidf_matrix'], 20)
        
        # 3. Entity features
        import spacy
        nlp = spacy.load("en_core_web_sm")
        entities = []
        for text in texts:
            doc = nlp(text)
            entities.extend([(ent.text, ent.label_) for ent in doc.ents])
        
        features['entity_counts'] = Counter([e[1] for e in entities])
        features['top_entities'] = Counter([e[0] for e in entities]).most_common(20)
        
        # 4. Hashtag features
        hashtags = []
        for text in texts:
            hashtags.extend(re.findall(r'#(\w+)', text))
        features['top_hashtags'] = Counter(hashtags).most_common(20)
        
        # 5. Emoji features
        import emoji
        emojis = []
        for text in texts:
            emojis.extend([c for c in text if c in emoji.EMOJI_DATA])
        features['top_emojis'] = Counter(emojis).most_common(10)
        
        return features
    
    def extract_behavioral_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Extract user behavioral features"""
        features = pd.DataFrame()
        
        # Temporal patterns
        features['peak_hour'] = df.groupby('user_id')['hour'].agg(lambda x: x.mode()[0])
        features['peak_day'] = df.groupby('user_id')['day_of_week'].agg(lambda x: x.mode()[0])
        features['posting_frequency'] = df.groupby('user_id').size()
        
        # Engagement patterns
        features['avg_engagement'] = df.groupby('user_id')['engagement_rate'].mean()
        features['max_engagement'] = df.groupby('user_id')['engagement_rate'].max()
        features['engagement_std'] = df.groupby('user_id')['engagement_rate'].std()
        
        # Content preferences
        features['avg_post_length'] = df.groupby('user_id')['text_clean'].apply(lambda x: np.mean([len(t) for t in x]))
        features['hashtag_usage_rate'] = df.groupby('user_id').apply(lambda x: sum(x['text'].str.contains('#')) / len(x))
        
        return features
    
    def extract_embedding_features(self, texts: List[str], model) -> np.ndarray:
        """Extract embeddings using sentence transformers"""
        embeddings = model.encode(
            texts,
            batch_size=32,
            show_progress_bar=True,
            normalize_embeddings=True
        )
        return embeddings
    
    def get_top_keywords(self, tfidf_matrix, n=20):
        """Extract top keywords from TF-IDF matrix"""
        feature_names = self.tfidf.get_feature_names_out()
        scores = np.asarray(tfidf_matrix.sum(axis=0)).ravel()
        top_indices = scores.argsort()[-n:][::-1]
        return [(feature_names[i], scores[i]) for i in top_indices]
```

### Feature Store Integration

```python
# Using Feast (Feature Store)
from feast import FeatureStore, Entity, FeatureView, Field
from feast.types import Float32, Int64, String
from datetime import timedelta

# Define entities
user = Entity(
    name="user_id",
    description="User identifier"
)

# Define feature view
from feast.infra.offline_stores.file_source import FileSource

user_features_source = FileSource(
    path="/data/user_features.parquet",
    timestamp_field="event_timestamp"
)

user_features_view = FeatureView(
    name="user_features",
    entities=[user],
    ttl=timedelta(days=30),
    schema=[
        Field(name="avg_engagement", dtype=Float32),
        Field(name="posting_frequency", dtype=Int64),
        Field(name="avg_post_length", dtype=Float32),
        Field(name="sentiment_score", dtype=Float32),
    ],
    source=user_features_source
)

# Initialize feature store
store = FeatureStore(repo_path=".")

# Get features for inference
features = store.get_online_features(
    features=[
        "user_features:avg_engagement",
        "user_features:posting_frequency",
        "user_features:sentiment_score"
    ],
    entity_rows=[{"user_id": user_id}]
).to_dict()
```

---

## Training vs Inference Architecture

### Training Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Training Infrastructure                    │
│                                                              │
│  ┌────────────┐     ┌──────────────┐     ┌──────────────┐  │
│  │  Data      │ →   │  Training    │  →  │  Model       │  │
│  │  Warehouse │     │  Cluster     │     │  Registry    │  │
│  │  (BigQuery)│     │  (Vertex AI) │     │  (MLflow)    │  │
│  └────────────┘     └──────────────┘     └──────────────┘  │
│                                                              │
│  Schedule: Daily (incremental), Weekly (full retrain)       │
│  Compute: GPU instances (A100 for large models)             │
│  Storage: GCS/S3 for model artifacts                        │
└─────────────────────────────────────────────────────────────┘
```

**Training Pipeline:**

```python
import mlflow
import torch
from transformers import Trainer, TrainingArguments
from datasets import Dataset

def train_sentiment_model():
    """Train custom sentiment model"""
    mlflow.set_experiment("sentiment_analysis")
    
    with mlflow.start_run():
        # Log parameters
        mlflow.log_param("model", "roberta-base")
        mlflow.log_param("learning_rate", 2e-5)
        mlflow.log_param("epochs", 3)
        
        # Load data
        train_dataset = Dataset.from_pandas(load_training_data())
        
        # Training arguments
        training_args = TrainingArguments(
            output_dir="./results",
            num_train_epochs=3,
            per_device_train_batch_size=16,
            per_device_eval_batch_size=64,
            warmup_steps=500,
            weight_decay=0.01,
            logging_dir="./logs",
            logging_steps=100,
            evaluation_strategy="steps",
            eval_steps=500,
            save_steps=1000,
            load_best_model_at_end=True,
        )
        
        # Train
        trainer = Trainer(
            model=model,
            args=training_args,
            train_dataset=train_dataset,
            eval_dataset=eval_dataset,
            compute_metrics=compute_metrics
        )
        
        trainer.train()
        
        # Log metrics
        eval_results = trainer.evaluate()
        mlflow.log_metrics(eval_results)
        
        # Log model
        mlflow.pytorch.log_model(model, "model")
        
        return model

def train_clustering_model():
    """Train and version clustering model"""
    from sklearn.cluster import MiniBatchKMeans
    
    # Load embeddings
    embeddings = load_user_embeddings()
    
    # Train multiple K values
    silhouette_scores = {}
    for k in range(5, 20):
        kmeans = MiniBatchKMeans(n_clusters=k, random_state=42, batch_size=1000)
        labels = kmeans.fit_predict(embeddings)
        
        from sklearn.metrics import silhouette_score
        score = silhouette_score(embeddings, labels, sample_size=10000)
        silhouette_scores[k] = score
    
    # Select best K
    best_k = max(silhouette_scores, key=silhouette_scores.get)
    
    # Train final model
    final_model = MiniBatchKMeans(n_clusters=best_k, random_state=42)
    final_model.fit(embeddings)
    
    # Save to model registry
    mlflow.sklearn.log_model(final_model, "clustering_model")
    mlflow.log_param("n_clusters", best_k)
    mlflow.log_metric("silhouette_score", silhouette_scores[best_k])
    
    return final_model
```

### Inference Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Inference Infrastructure                    │
│                                                              │
│  ┌────────────┐     ┌──────────────┐     ┌──────────────┐  │
│  │  API       │ →   │  Model       │  →  │  Response    │  │
│  │  Gateway   │     │  Serving     │     │  Cache       │  │
│  │  (FastAPI) │     │  (Ray Serve) │     │  (Redis)     │  │
│  └────────────┘     └──────────────┘     └──────────────┘  │
│                                                              │
│  Latency Target: <200ms (p95)                               │
│  Throughput: 1000 req/s                                     │
│  Auto-scaling: Based on CPU/GPU utilization                 │
└─────────────────────────────────────────────────────────────┘
```

**Inference Pipeline:**

```python
from ray import serve
import ray
from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np

app = FastAPI()

@serve.deployment(
    num_replicas=3,
    ray_actor_options={"num_gpus": 0.5}
)
@serve.ingress(app)
class SentimentAnalyzer:
    def __init__(self):
        from transformers import pipeline
        self.model = pipeline(
            "sentiment-analysis",
            model="cardiffnlp/twitter-roberta-base-sentiment-latest",
            device=0
        )
        
    @app.post("/analyze")
    async def analyze(self, request: dict):
        texts = request["texts"]
        results = self.model(texts)
        return {"sentiments": results}

@serve.deployment(
    num_replicas=2,
    ray_actor_options={"num_gpus": 1.0}
)
class AdGenerator:
    def __init__(self):
        import anthropic
        self.client = anthropic.Anthropic()
        
    async def generate_ad_copy(self, persona: dict, product: dict):
        """Generate ad copy using Claude"""
        prompt = self.build_prompt(persona, product)
        
        message = self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            temperature=0.7,
            messages=[{"role": "user", "content": prompt}]
        )
        
        return message.content[0].text
    
    def build_prompt(self, persona, product):
        return f"""Generate 3 ad copy variations for:

Persona: {persona}
Product: {product}

Requirements:
- Tone: {persona.get('tone', 'friendly')}
- Length: 150-200 characters
- Include CTA
- Highlight benefits that match persona interests

Output as JSON with keys: headline, body, cta"""

# Deploy
ray.init()
serve.run(SentimentAnalyzer.bind())
serve.run(AdGenerator.bind())
```

---

## Model Serving Infrastructure

### Option 1: Ray Serve (Recommended for Complex Pipelines)

```python
from ray import serve
import ray

@serve.deployment(
    autoscaling_config={
        "min_replicas": 2,
        "max_replicas": 10,
        "target_num_ongoing_requests_per_replica": 5,
    },
    ray_actor_options={"num_gpus": 0.5}
)
class MLPipeline:
    def __init__(self):
        # Load all models once
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        self.sentiment_model = pipeline("sentiment-analysis")
        self.clustering_model = mlflow.sklearn.load_model("models:/clustering/production")
        
    async def process(self, user_data: dict):
        # Extract embeddings
        embeddings = self.embedding_model.encode(user_data['texts'])
        
        # Sentiment analysis
        sentiments = self.sentiment_model(user_data['texts'])
        
        # Cluster assignment
        cluster = self.clustering_model.predict([embeddings.mean(axis=0)])[0]
        
        return {
            "cluster": int(cluster),
            "sentiment": sentiments,
            "embeddings": embeddings.tolist()
        }

serve.run(MLPipeline.bind())
```

### Option 2: Triton Inference Server (For High-Throughput)

```python
# Convert PyTorch model to ONNX for Triton
import torch
from transformers import AutoModel, AutoTokenizer

model = AutoModel.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
tokenizer = AutoTokenizer.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")

dummy_input = tokenizer("sample text", return_tensors="pt")

torch.onnx.export(
    model,
    (dummy_input['input_ids'], dummy_input['attention_mask']),
    "model.onnx",
    input_names=['input_ids', 'attention_mask'],
    output_names=['output'],
    dynamic_axes={
        'input_ids': {0: 'batch_size', 1: 'sequence'},
        'attention_mask': {0: 'batch_size', 1: 'sequence'},
        'output': {0: 'batch_size'}
    }
)
```

**Triton Model Configuration:**

```ini
# config.pbtxt
name: "sentence_transformer"
platform: "onnxruntime_onnx"
max_batch_size: 32

input [
  {
    name: "input_ids"
    data_type: TYPE_INT64
    dims: [-1]
  },
  {
    name: "attention_mask"
    data_type: TYPE_INT64
    dims: [-1]
  }
]

output [
  {
    name: "output"
    data_type: TYPE_FP32
    dims: [384]
  }
]

instance_group [
  {
    count: 2
    kind: KIND_GPU
  }
]

dynamic_batching {
  max_queue_delay_microseconds: 1000
}
```

### Option 3: vLLM (For LLM Serving)

```python
from vllm import LLM, SamplingParams

# Initialize vLLM
llm = LLM(
    model="meta-llama/Meta-Llama-3.1-70B-Instruct",
    tensor_parallel_size=4,  # 4 GPUs
    max_model_len=4096,
    gpu_memory_utilization=0.9
)

sampling_params = SamplingParams(
    temperature=0.7,
    top_p=0.9,
    max_tokens=512
)

def generate_batch_ads(prompts: List[str]):
    """Generate ads in batch with vLLM"""
    outputs = llm.generate(prompts, sampling_params)
    return [output.outputs[0].text for output in outputs]

# FastAPI endpoint
@app.post("/generate_ads_batch")
async def generate_ads_batch(request: dict):
    prompts = request["prompts"]
    ads = generate_batch_ads(prompts)
    return {"ads": ads}
```

---

## API Integrations

### 1. OpenAI Integration

```python
import openai
from tenacity import retry, stop_after_attempt, wait_exponential
import asyncio

class OpenAIService:
    def __init__(self, api_key: str):
        self.client = openai.AsyncOpenAI(api_key=api_key)
        
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10)
    )
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings with retry logic"""
        response = await self.client.embeddings.create(
            model="text-embedding-3-small",
            input=texts,
            dimensions=512  # Reduced dimensions for cost optimization
        )
        return [item.embedding for item in response.data]
    
    @retry(stop=stop_after_attempt(3))
    async def generate_image(self, prompt: str, quality: str = "standard") -> str:
        """Generate image with DALL-E 3"""
        response = await self.client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality=quality,  # "standard" or "hd"
            n=1
        )
        return response.data[0].url
    
    async def generate_ad_copy(self, persona: dict, product: dict) -> dict:
        """Generate ad copy with GPT-4o"""
        response = await self.client.chat.completions.create(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are an expert ad copywriter."},
                {"role": "user", "content": self.build_ad_prompt(persona, product)}
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=500
        )
        return json.loads(response.choices[0].message.content)
```

### 2. Anthropic Integration

```python
import anthropic
from anthropic import AsyncAnthropic

class AnthropicService:
    def __init__(self, api_key: str):
        self.client = AsyncAnthropic(api_key=api_key)
        
    async def generate_persona(self, cluster_data: dict) -> dict:
        """Generate persona using Claude with structured output"""
        message = await self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=2048,
            temperature=0.5,
            messages=[{
                "role": "user",
                "content": f"""Analyze this audience cluster and create a detailed persona:

Cluster Data:
- Size: {cluster_data['size']} users
- Top Interests: {', '.join(cluster_data['interests'])}
- Sentiment: {cluster_data['avg_sentiment']}
- Engagement: {cluster_data['avg_engagement']}
- Demographics: {cluster_data['demographics']}

Create a persona with:
1. Name and demographic profile
2. Psychographic traits
3. Pain points and motivations
4. Content preferences
5. Buying behavior
6. Recommended ad approach

Return as JSON."""
            }]
        )
        return json.loads(message.content[0].text)
    
    async def generate_ad_variations(self, persona: dict, product: dict, n: int = 5):
        """Generate multiple ad variations"""
        message = await self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1500,
            temperature=0.8,
            messages=[{
                "role": "user",
                "content": f"""Generate {n} distinct ad copy variations for:

Persona: {json.dumps(persona, indent=2)}
Product: {json.dumps(product, indent=2)}

Each variation should test a different angle:
1. Emotional appeal
2. Rational/feature-focused
3. Social proof
4. Urgency/scarcity
5. Value proposition

Return as JSON array with: headline, body, cta, angle"""
            }]
        )
        return json.loads(message.content[0].text)
    
    # Batch API for cost optimization
    async def create_batch_request(self, requests: List[dict]):
        """Create batch request for 50% cost savings"""
        batch = await self.client.messages.batches.create(
            requests=[
                {
                    "custom_id": req["id"],
                    "params": {
                        "model": "claude-3-5-sonnet-20241022",
                        "max_tokens": 1024,
                        "messages": req["messages"]
                    }
                }
                for req in requests
            ]
        )
        return batch.id
    
    async def retrieve_batch_results(self, batch_id: str):
        """Retrieve batch results"""
        batch = await self.client.messages.batches.retrieve(batch_id)
        
        if batch.processing_status == "ended":
            results = []
            async for result in self.client.messages.batches.results(batch_id):
                results.append(result)
            return results
        else:
            return {"status": batch.processing_status}
```

### 3. Hugging Face Integration

```python
from huggingface_hub import InferenceClient
import aiohttp

class HuggingFaceService:
    def __init__(self, api_key: str):
        self.client = InferenceClient(token=api_key)
        self.base_url = "https://api-inference.huggingface.co/models"
        
    async def generate_image_sdxl(self, prompt: str) -> bytes:
        """Generate image using SDXL via Inference API"""
        image = self.client.text_to_image(
            prompt=prompt,
            model="stabilityai/stable-diffusion-xl-base-1.0"
        )
        return image
    
    async def analyze_sentiment(self, text: str) -> dict:
        """Sentiment analysis using Inference API"""
        result = self.client.text_classification(
            text=text,
            model="cardiffnlp/twitter-roberta-base-sentiment-latest"
        )
        return result
    
    async def extract_topics(self, texts: List[str]) -> List[str]:
        """Topic extraction using zero-shot classification"""
        candidate_labels = [
            "technology", "fashion", "food", "travel", "fitness",
            "business", "entertainment", "sports", "politics", "health"
        ]
        
        results = self.client.zero_shot_classification(
            text=texts[0],  # Example
            labels=candidate_labels,
            multi_label=True
        )
        return results
```

### 4. Social Media API Integration

```python
import tweepy
import facebook
from instagram_private_api import Client as InstagramAPI

class SocialMediaCollector:
    def __init__(self, credentials: dict):
        # Twitter/X
        self.twitter_client = tweepy.Client(
            bearer_token=credentials['twitter_bearer_token']
        )
        
        # Instagram
        self.instagram_client = InstagramAPI(
            username=credentials['instagram_username'],
            password=credentials['instagram_password']
        )
        
    async def fetch_user_posts(self, user_id: str, platform: str) -> List[dict]:
        """Fetch user posts from various platforms"""
        if platform == "twitter":
            return await self.fetch_twitter_posts(user_id)
        elif platform == "instagram":
            return await self.fetch_instagram_posts(user_id)
        # Add more platforms
        
    async def fetch_twitter_posts(self, user_id: str) -> List[dict]:
        """Fetch Twitter posts"""
        tweets = self.twitter_client.get_users_tweets(
            id=user_id,
            max_results=100,
            tweet_fields=['created_at', 'public_metrics', 'entities']
        )
        
        return [{
            'text': tweet.text,
            'created_at': tweet.created_at,
            'likes': tweet.public_metrics['like_count'],
            'retweets': tweet.public_metrics['retweet_count'],
            'replies': tweet.public_metrics['reply_count']
        } for tweet in tweets.data]
    
    async def fetch_engagement_data(self, post_id: str, platform: str) -> dict:
        """Fetch detailed engagement data"""
        # Implementation for each platform
        pass
```

---

## Vector Databases

### Comparison Matrix

| Database | Best For | Latency | Cost | Scalability |
|----------|----------|---------|------|-------------|
| **Pinecone** | Production, managed | <50ms | $$ | Excellent |
| **Weaviate** | Hybrid search, self-hosted | <100ms | $ | Very Good |
| **Qdrant** | High performance, self-hosted | <30ms | $ | Excellent |
| **Milvus** | Large scale, open source | <50ms | $ | Excellent |
| **ChromaDB** | Development, embedded | <100ms | Free | Limited |

### Implementation: Pinecone (Recommended for Production)

```python
from pinecone import Pinecone, ServerlessSpec
import numpy as np
from typing import List, Dict

class VectorStore:
    def __init__(self, api_key: str):
        self.pc = Pinecone(api_key=api_key)
        self.index_name = "user-embeddings"
        
        # Create index if doesn't exist
        if self.index_name not in self.pc.list_indexes().names():
            self.pc.create_index(
                name=self.index_name,
                dimension=384,  # all-MiniLM-L6-v2 dimension
                metric="cosine",
                spec=ServerlessSpec(
                    cloud="aws",
                    region="us-east-1"
                )
            )
        
        self.index = self.pc.Index(self.index_name)
    
    def upsert_embeddings(self, user_ids: List[str], embeddings: np.ndarray, 
                         metadata: List[dict]):
        """Insert or update user embeddings"""
        vectors = [
            {
                "id": user_id,
                "values": embedding.tolist(),
                "metadata": meta
            }
            for user_id, embedding, meta in zip(user_ids, embeddings, metadata)
        ]
        
        # Batch upsert (max 100 vectors per request)
        batch_size = 100
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i+batch_size]
            self.index.upsert(vectors=batch)
    
    def query_similar_users(self, query_embedding: np.ndarray, 
                           top_k: int = 10, 
                           filter_dict: dict = None) -> List[dict]:
        """Find similar users based on embedding"""
        results = self.index.query(
            vector=query_embedding.tolist(),
            top_k=top_k,
            include_metadata=True,
            filter=filter_dict  # e.g., {"cluster": 5, "sentiment": {"$gte": 0.5}}
        )
        
        return [
            {
                "user_id": match.id,
                "score": match.score,
                "metadata": match.metadata
            }
            for match in results.matches
        ]
    
    def query_by_metadata(self, filter_dict: dict, limit: int = 100):
        """Query users by metadata filters"""
        # Pinecone doesn't support pure metadata queries
        # Use dummy vector with high limit
        dummy_vector = [0.0] * 384
        results = self.index.query(
            vector=dummy_vector,
            top_k=limit,
            filter=filter_dict,
            include_metadata=True
        )
        return results.matches
    
    def update_metadata(self, user_id: str, metadata: dict):
        """Update user metadata"""
        self.index.update(id=user_id, set_metadata=metadata)
    
    def delete_users(self, user_ids: List[str]):
        """Delete user embeddings"""
        self.index.delete(ids=user_ids)
    
    def get_stats(self):
        """Get index statistics"""
        return self.index.describe_index_stats()
```

### Implementation: Qdrant (Alternative, Self-Hosted)

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct, Filter, FieldCondition, MatchValue

class QdrantVectorStore:
    def __init__(self, host: str = "localhost", port: int = 6333):
        self.client = QdrantClient(host=host, port=port)
        self.collection_name = "user_embeddings"
        
        # Create collection
        self.client.recreate_collection(
            collection_name=self.collection_name,
            vectors_config=VectorParams(size=384, distance=Distance.COSINE),
        )
    
    def upsert_embeddings(self, user_ids: List[str], embeddings: np.ndarray, 
                         metadata: List[dict]):
        """Insert embeddings with metadata"""
        points = [
            PointStruct(
                id=hash(user_id),  # Convert to int
                vector=embedding.tolist(),
                payload={**meta, "user_id": user_id}
            )
            for user_id, embedding, meta in zip(user_ids, embeddings, metadata)
        ]
        
        self.client.upsert(
            collection_name=self.collection_name,
            points=points
        )
    
    def query_similar_users(self, query_embedding: np.ndarray, 
                           top_k: int = 10,
                           filter_conditions: dict = None) -> List[dict]:
        """Query similar users with optional filters"""
        search_filter = None
        if filter_conditions:
            search_filter = Filter(
                must=[
                    FieldCondition(
                        key=key,
                        match=MatchValue(value=value)
                    )
                    for key, value in filter_conditions.items()
                ]
            )
        
        results = self.client.search(
            collection_name=self.collection_name,
            query_vector=query_embedding.tolist(),
            limit=top_k,
            query_filter=search_filter
        )
        
        return [
            {
                "user_id": hit.payload["user_id"],
                "score": hit.score,
                "metadata": hit.payload
            }
            for hit in results
        ]
```

### Hybrid Search with Weaviate

```python
import weaviate
from weaviate.classes.config import Configure, Property, DataType

class WeaviateHybridSearch:
    def __init__(self, url: str, api_key: str):
        self.client = weaviate.Client(
            url=url,
            auth_client_secret=weaviate.AuthApiKey(api_key=api_key)
        )
        
        # Create schema
        self.create_schema()
    
    def create_schema(self):
        """Create Weaviate schema"""
        user_class = {
            "class": "User",
            "description": "Social media user profile",
            "vectorizer": "none",  # We provide our own vectors
            "properties": [
                {"name": "user_id", "dataType": ["string"]},
                {"name": "interests", "dataType": ["text"]},
                {"name": "sentiment_score", "dataType": ["number"]},
                {"name": "cluster_id", "dataType": ["int"]},
                {"name": "engagement_rate", "dataType": ["number"]},
            ]
        }
        
        if not self.client.schema.exists("User"):
            self.client.schema.create_class(user_class)
    
    def add_user(self, user_id: str, embedding: np.ndarray, properties: dict):
        """Add user with vector"""
        self.client.data_object.create(
            class_name="User",
            data_object={**properties, "user_id": user_id},
            vector=embedding.tolist()
        )
    
    def hybrid_search(self, query_text: str, query_vector: np.ndarray, 
                     alpha: float = 0.5, limit: int = 10):
        """
        Hybrid search combining vector and keyword search
        alpha=0: pure keyword, alpha=1: pure vector
        """
        result = (
            self.client.query
            .get("User", ["user_id", "interests", "sentiment_score"])
            .with_hybrid(
                query=query_text,
                vector=query_vector.tolist(),
                alpha=alpha
            )
            .with_limit(limit)
            .do()
        )
        
        return result["data"]["Get"]["User"]
```

---

## Real-time vs Batch Processing

### Decision Matrix

| Task | Processing Mode | Latency | Technology |
|------|----------------|---------|------------|
| Follower data ingestion | Batch (hourly) | N/A | Apache Airflow |
| Embedding generation | Batch (daily) | N/A | Apache Spark |
| Sentiment analysis | Real-time | <100ms | Ray Serve |
| Clustering update | Batch (weekly) | N/A | Python/scikit-learn |
| Persona generation | Batch (weekly) | N/A | Claude API (batch) |
| Ad copy generation | Real-time | <2s | Claude API |
| Ad image generation | Async/Queue | 5-30s | DALL-E/SDXL + Celery |
| A/B test analysis | Batch (daily) | N/A | SQL + Python |
| Recommendation | Real-time | <50ms | Vector DB |

### Batch Processing Pipeline (Apache Airflow)

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'ml-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'daily_ml_pipeline',
    default_args=default_args,
    description='Daily ML processing pipeline',
    schedule_interval='0 2 * * *',  # 2 AM daily
    catchup=False
)

def extract_social_data(**context):
    """Extract data from social media APIs"""
    from socialengineering.data import SocialMediaCollector
    
    collector = SocialMediaCollector()
    data = collector.fetch_yesterday_data()
    
    # Store in data lake
    data.to_parquet(f's3://data-lake/raw/{context["ds"]}.parquet')

def generate_embeddings(**context):
    """Generate embeddings for all new users"""
    import pandas as pd
    from sentence_transformers import SentenceTransformer
    
    # Load data
    df = pd.read_parquet(f's3://data-lake/raw/{context["ds"]}.parquet')
    
    # Generate embeddings
    model = SentenceTransformer('all-MiniLM-L6-v2')
    embeddings = model.encode(df['text'].tolist(), batch_size=256, show_progress_bar=True)
    
    # Store embeddings
    np.save(f's3://data-lake/embeddings/{context["ds"]}.npy', embeddings)
    
    # Upload to vector DB
    vector_store = VectorStore()
    vector_store.upsert_embeddings(
        user_ids=df['user_id'].tolist(),
        embeddings=embeddings,
        metadata=df[['sentiment', 'cluster', 'engagement_rate']].to_dict('records')
    )

def update_clusters(**context):
    """Update user clusters weekly"""
    # Load all embeddings
    embeddings = load_all_embeddings()
    
    # Incremental clustering
    from sklearn.cluster import MiniBatchKMeans
    clusterer = MiniBatchKMeans(n_clusters=15, random_state=42)
    labels = clusterer.fit_predict(embeddings)
    
    # Update cluster assignments
    update_cluster_assignments(labels)

def generate_personas(**context):
    """Generate personas for each cluster"""
    clusters = get_cluster_statistics()
    
    # Use Claude Batch API for cost savings
    anthropic_service = AnthropicService()
    
    requests = [
        {
            "id": f"cluster_{i}",
            "messages": [{
                "role": "user",
                "content": f"Generate persona for: {cluster}"
            }]
        }
        for i, cluster in enumerate(clusters)
    ]
    
    batch_id = anthropic_service.create_batch_request(requests)
    
    # Store batch ID for later retrieval
    context['ti'].xcom_push(key='persona_batch_id', value=batch_id)

# Define tasks
extract_task = PythonOperator(
    task_id='extract_social_data',
    python_callable=extract_social_data,
    dag=dag
)

embedding_task = PythonOperator(
    task_id='generate_embeddings',
    python_callable=generate_embeddings,
    dag=dag
)

cluster_task = PythonOperator(
    task_id='update_clusters',
    python_callable=update_clusters,
    dag=dag,
    schedule_interval='0 2 * * 0'  # Weekly on Sunday
)

persona_task = PythonOperator(
    task_id='generate_personas',
    python_callable=generate_personas,
    dag=dag,
    schedule_interval='0 3 * * 0'  # Weekly on Sunday
)

# Define dependencies
extract_task >> embedding_task >> cluster_task >> persona_task
```

### Real-time Processing (FastAPI + Ray Serve)

```python
from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel
import asyncio
import redis
from typing import List, Optional

app = FastAPI()

# Redis for caching
redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

class UserAnalysisRequest(BaseModel):
    user_id: str
    platform: str
    include_ads: bool = True

class AdGenerationRequest(BaseModel):
    persona_id: str
    product_id: str
    num_variations: int = 3

@app.post("/analyze_user")
async def analyze_user(request: UserAnalysisRequest, background_tasks: BackgroundTasks):
    """Real-time user analysis"""
    
    # Check cache
    cache_key = f"user_analysis:{request.user_id}"
    cached_result = redis_client.get(cache_key)
    
    if cached_result:
        return json.loads(cached_result)
    
    # Fetch user data
    social_collector = SocialMediaCollector()
    user_data = await social_collector.fetch_user_data(
        request.user_id, 
        request.platform
    )
    
    # Real-time processing
    results = await process_user_realtime(user_data)
    
    # Cache results (1 hour TTL)
    redis_client.setex(cache_key, 3600, json.dumps(results))
    
    # Trigger background ad generation if requested
    if request.include_ads:
        background_tasks.add_task(
            generate_ads_background,
            results['persona_id'],
            request.user_id
        )
    
    return results

async def process_user_realtime(user_data: dict) -> dict:
    """Process user data in real-time"""
    
    # Parallel processing
    sentiment_task = analyze_sentiment_async(user_data['texts'])
    embedding_task = generate_embeddings_async(user_data['texts'])
    
    sentiment, embeddings = await asyncio.gather(
        sentiment_task,
        embedding_task
    )
    
    # Find cluster (vector DB lookup)
    vector_store = VectorStore()
    avg_embedding = embeddings.mean(axis=0)
    similar_users = vector_store.query_similar_users(avg_embedding, top_k=10)
    
    # Majority vote for cluster
    cluster_counts = Counter([u['metadata']['cluster'] for u in similar_users])
    assigned_cluster = cluster_counts.most_common(1)[0][0]
    
    return {
        "user_id": user_data['user_id'],
        "sentiment": sentiment,
        "cluster": assigned_cluster,
        "persona_id": f"persona_{assigned_cluster}",
        "interests": extract_top_interests(user_data['texts']),
        "engagement_score": calculate_engagement_score(user_data)
    }

@app.post("/generate_ads")
async def generate_ads(request: AdGenerationRequest):
    """Real-time ad generation"""
    
    # Check cache
    cache_key = f"ads:{request.persona_id}:{request.product_id}"
    cached_ads = redis_client.get(cache_key)
    
    if cached_ads:
        return json.loads(cached_ads)
    
    # Load persona
    persona = load_persona(request.persona_id)
    product = load_product(request.product_id)
    
    # Generate ad copy (real-time)
    anthropic_service = AnthropicService()
    ad_variations = await anthropic_service.generate_ad_variations(
        persona, 
        product, 
        request.num_variations
    )
    
    # Cache for 24 hours
    redis_client.setex(cache_key, 86400, json.dumps(ad_variations))
    
    return {
        "persona_id": request.persona_id,
        "product_id": request.product_id,
        "variations": ad_variations
    }

async def generate_ads_background(persona_id: str, user_id: str):
    """Background task for ad generation"""
    # This runs asynchronously, doesn't block the response
    pass
```

### Stream Processing (Apache Kafka + Flink)

```python
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import FlinkKafkaConsumer, FlinkKafkaProducer
from pyflink.common.serialization import SimpleStringSchema
from pyflink.datastream.functions import MapFunction
import json

class SentimentAnalysisFunction(MapFunction):
    def __init__(self):
        self.analyzer = None
    
    def open(self, runtime_context):
        from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        self.analyzer = SentimentIntensityAnalyzer()
    
    def map(self, value):
        data = json.loads(value)
        sentiment = self.analyzer.polarity_scores(data['text'])
        data['sentiment'] = sentiment['compound']
        return json.dumps(data)

def run_streaming_pipeline():
    """Real-time streaming pipeline for social media data"""
    env = StreamExecutionEnvironment.get_execution_environment()
    
    # Kafka source
    kafka_consumer = FlinkKafkaConsumer(
        topics='social-media-posts',
        deserialization_schema=SimpleStringSchema(),
        properties={
            'bootstrap.servers': 'localhost:9092',
            'group.id': 'ml-pipeline'
        }
    )
    
    # Kafka sink
    kafka_producer = FlinkKafkaProducer(
        topic='processed-posts',
        serialization_schema=SimpleStringSchema(),
        producer_config={
            'bootstrap.servers': 'localhost:9092'
        }
    )
    
    # Processing pipeline
    stream = env.add_source(kafka_consumer)
    
    processed_stream = (
        stream
        .map(SentimentAnalysisFunction())
        # Add more transformations
    )
    
    processed_stream.add_sink(kafka_producer)
    
    env.execute("Social Media Streaming Pipeline")
```

---

## Model Versioning and A/B Testing

### MLflow Model Registry

```python
import mlflow
from mlflow.tracking import MlflowClient

class ModelVersionManager:
    def __init__(self):
        self.client = MlflowClient()
        mlflow.set_tracking_uri("http://mlflow-server:5000")
    
    def register_model(self, model_name: str, model_uri: str, 
                      description: str = None, tags: dict = None):
        """Register a new model version"""
        result = mlflow.register_model(
            model_uri=model_uri,
            name=model_name,
            tags=tags or {}
        )
        
        if description:
            self.client.update_model_version(
                name=model_name,
                version=result.version,
                description=description
            )
        
        return result
    
    def promote_to_production(self, model_name: str, version: int):
        """Promote model version to production"""
        # Archive current production version
        current_prod = self.client.get_latest_versions(
            model_name, 
            stages=["Production"]
        )
        
        for model_version in current_prod:
            self.client.transition_model_version_stage(
                name=model_name,
                version=model_version.version,
                stage="Archived"
            )
        
        # Promote new version
        self.client.transition_model_version_stage(
            name=model_name,
            version=version,
            stage="Production"
        )
    
    def promote_to_staging(self, model_name: str, version: int):
        """Promote model version to staging for A/B testing"""
        self.client.transition_model_version_stage(
            name=model_name,
            version=version,
            stage="Staging"
        )
    
    def load_production_model(self, model_name: str):
        """Load current production model"""
        model_uri = f"models:/{model_name}/Production"
        return mlflow.pyfunc.load_model(model_uri)
    
    def load_staging_model(self, model_name: str):
        """Load staging model for A/B testing"""
        model_uri = f"models:/{model_name}/Staging"
        return mlflow.pyfunc.load_model(model_uri)
    
    def compare_models(self, model_name: str, version_a: int, version_b: int):
        """Compare two model versions"""
        # Get metrics for both versions
        metrics_a = self.client.get_run(
            self.client.get_model_version(model_name, version_a).run_id
        ).data.metrics
        
        metrics_b = self.client.get_run(
            self.client.get_model_version(model_name, version_b).run_id
        ).data.metrics
        
        comparison = {
            "version_a": {"version": version_a, "metrics": metrics_a},
            "version_b": {"version": version_b, "metrics": metrics_b}
        }
        
        return comparison
```

### A/B Testing Framework

```python
import hashlib
from dataclasses import dataclass
from typing import Dict, List, Optional
from enum import Enum

class VariantType(Enum):
    CONTROL = "control"
    TREATMENT = "treatment"

@dataclass
class Experiment:
    id: str
    name: str
    variants: Dict[str, float]  # variant_name -> traffic_allocation
    metrics: List[str]
    start_date: datetime
    end_date: Optional[datetime] = None
    status: str = "active"

class ABTestingFramework:
    def __init__(self, redis_client, analytics_db):
        self.redis = redis_client
        self.db = analytics_db
        self.experiments: Dict[str, Experiment] = {}
    
    def create_experiment(self, experiment: Experiment):
        """Create a new A/B test experiment"""
        # Validate traffic allocation sums to 1.0
        if not abs(sum(experiment.variants.values()) - 1.0) < 0.001:
            raise ValueError("Traffic allocation must sum to 1.0")
        
        self.experiments[experiment.id] = experiment
        
        # Store in Redis
        self.redis.set(
            f"experiment:{experiment.id}",
            json.dumps(experiment.__dict__, default=str),
            ex=86400 * 30  # 30 days
        )
    
    def assign_variant(self, user_id: str, experiment_id: str) -> str:
        """Assign user to a variant (consistent hashing)"""
        # Check if user already assigned
        cache_key = f"assignment:{experiment_id}:{user_id}"
        cached_variant = self.redis.get(cache_key)
        
        if cached_variant:
            return cached_variant
        
        # Consistent hashing for assignment
        experiment = self.experiments.get(experiment_id)
        if not experiment:
            return "control"
        
        # Hash user_id + experiment_id
        hash_input = f"{user_id}:{experiment_id}".encode('utf-8')
        hash_value = int(hashlib.md5(hash_input).hexdigest(), 16)
        probability = (hash_value % 10000) / 10000.0
        
        # Assign based on traffic allocation
        cumulative_prob = 0.0
        for variant_name, allocation in sorted(experiment.variants.items()):
            cumulative_prob += allocation
            if probability < cumulative_prob:
                # Cache assignment
                self.redis.set(cache_key, variant_name, ex=86400 * 30)
                return variant_name
        
        return "control"
    
    def track_event(self, user_id: str, experiment_id: str, 
                   metric_name: str, value: float):
        """Track experiment metric"""
        variant = self.assign_variant(user_id, experiment_id)
        
        # Store event
        event = {
            "experiment_id": experiment_id,
            "user_id": user_id,
            "variant": variant,
            "metric_name": metric_name,
            "value": value,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Write to analytics DB (e.g., BigQuery, ClickHouse)
        self.db.insert("experiment_events", event)
        
        # Update real-time counters in Redis
        counter_key = f"metric:{experiment_id}:{variant}:{metric_name}"
        self.redis.hincrby(counter_key, "count", 1)
        self.redis.hincrbyfloat(counter_key, "sum", value)
    
    def get_experiment_results(self, experiment_id: str) -> Dict:
        """Get current experiment results"""
        experiment = self.experiments.get(experiment_id)
        if not experiment:
            return {}
        
        results = {}
        
        for variant in experiment.variants.keys():
            variant_results = {}
            
            for metric_name in experiment.metrics:
                counter_key = f"metric:{experiment_id}:{variant}:{metric_name}"
                count = int(self.redis.hget(counter_key, "count") or 0)
                total = float(self.redis.hget(counter_key, "sum") or 0)
                
                variant_results[metric_name] = {
                    "count": count,
                    "sum": total,
                    "mean": total / count if count > 0 else 0
                }
            
            results[variant] = variant_results
        
        return results
    
    def calculate_statistical_significance(self, experiment_id: str, 
                                          metric_name: str) -> Dict:
        """Calculate statistical significance using t-test"""
        from scipy import stats
        
        # Get data from analytics DB
        query = f"""
        SELECT variant, value
        FROM experiment_events
        WHERE experiment_id = '{experiment_id}'
        AND metric_name = '{metric_name}'
        """
        
        df = self.db.query(query)
        
        # Get control and treatment groups
        control_data = df[df['variant'] == 'control']['value'].values
        treatment_data = df[df['variant'] == 'treatment']['value'].values
        
        # Perform t-test
        t_statistic, p_value = stats.ttest_ind(treatment_data, control_data)
        
        # Calculate confidence interval
        control_mean = control_data.mean()
        treatment_mean = treatment_data.mean()
        lift = ((treatment_mean - control_mean) / control_mean) * 100
        
        return {
            "metric": metric_name,
            "control_mean": float(control_mean),
            "treatment_mean": float(treatment_mean),
            "lift_percentage": float(lift),
            "t_statistic": float(t_statistic),
            "p_value": float(p_value),
            "significant": p_value < 0.05,
            "confidence_level": "95%"
        }

# Integration with ad serving
class ABTestingAdServer:
    def __init__(self, ab_framework: ABTestingFramework):
        self.ab_framework = ab_framework
        self.model_manager = ModelVersionManager()
    
    def serve_ad(self, user_id: str, context: dict) -> dict:
        """Serve ad with A/B testing"""
        
        # Check active experiments
        experiment_id = "ad_copy_model_v2"
        variant = self.ab_framework.assign_variant(user_id, experiment_id)
        
        # Load appropriate model version
        if variant == "control":
            model = self.model_manager.load_production_model("ad_generator")
        else:  # treatment
            model = self.model_manager.load_staging_model("ad_generator")
        
        # Generate ad
        ad = model.predict(context)
        
        # Track impression
        self.ab_framework.track_event(
            user_id, 
            experiment_id, 
            "impression", 
            1.0
        )
        
        return {
            "ad": ad,
            "variant": variant,
            "experiment_id": experiment_id
        }
    
    def track_click(self, user_id: str, experiment_id: str):
        """Track ad click"""
        self.ab_framework.track_event(
            user_id,
            experiment_id,
            "click",
            1.0
        )
    
    def track_conversion(self, user_id: str, experiment_id: str, value: float):
        """Track conversion"""
        self.ab_framework.track_event(
            user_id,
            experiment_id,
            "conversion_value",
            value
        )
```

---

## Cost Optimization

### 1. API Cost Management

```python
class CostOptimizedAPIRouter:
    def __init__(self):
        self.openai_service = OpenAIService()
        self.anthropic_service = AnthropicService()
        self.local_model = self.load_local_model()
        
        # Cost per 1M tokens (approximate)
        self.costs = {
            "gpt-4o": {"input": 2.50, "output": 10.00},
            "gpt-4o-mini": {"input": 0.15, "output": 0.60},
            "claude-3-5-sonnet": {"input": 3.00, "output": 15.00},
            "claude-3-haiku": {"input": 0.25, "output": 1.25},
            "local": {"input": 0.00, "output": 0.00}
        }
    
    def select_model(self, task: str, quality_requirement: str, 
                    input_length: int) -> str:
        """
        Intelligent model selection based on task, quality, and cost
        """
        # Simple tasks -> use cheaper models
        if task in ["sentiment", "classification", "short_copy"]:
            if quality_requirement == "high":
                return "claude-3-haiku"
            else:
                return "local"
        
        # Complex creative tasks -> use premium models
        elif task in ["long_copy", "persona_generation", "image_prompt"]:
            if quality_requirement == "premium":
                return "claude-3-5-sonnet"
            else:
                return "gpt-4o-mini"
        
        # Very long inputs -> use models with good cost/performance
        elif input_length > 10000:
            return "gpt-4o-mini"
        
        return "local"
    
    async def generate_with_fallback(self, prompt: str, task: str, 
                                    quality: str = "medium"):
        """
        Generate with cost optimization and fallbacks
        """
        model = self.select_model(task, quality, len(prompt))
        
        try:
            if model == "claude-3-5-sonnet":
                result = await self.anthropic_service.generate(prompt, "claude-3-5-sonnet-20241022")
            elif model == "claude-3-haiku":
                result = await self.anthropic_service.generate(prompt, "claude-3-haiku-20240307")
            elif model == "gpt-4o-mini":
                result = await self.openai_service.generate(prompt, "gpt-4o-mini")
            elif model == "local":
                result = await self.local_model.generate(prompt)
            
            # Track cost
            self.track_cost(model, prompt, result)
            
            return result
            
        except Exception as e:
            # Fallback to local model
            logger.warning(f"API failed, falling back to local: {e}")
            return await self.local_model.generate(prompt)
    
    def track_cost(self, model: str, prompt: str, result: str):
        """Track API costs"""
        input_tokens = len(prompt) / 4  # Rough estimate
        output_tokens = len(result) / 4
        
        cost = (
            (input_tokens / 1_000_000) * self.costs[model]["input"] +
            (output_tokens / 1_000_000) * self.costs[model]["output"]
        )
        
        # Log to monitoring system
        logger.info(f"API cost: ${cost:.4f} for model {model}")
        
        # Store in database for analytics
        metrics.record_cost(model, cost)
```

### 2. Batch Processing for Cost Reduction

```python
class BatchProcessor:
    def __init__(self):
        self.anthropic_service = AnthropicService()
        self.batch_queue = []
        self.batch_size = 1000
    
    async def queue_request(self, request: dict):
        """Queue request for batch processing"""
        self.batch_queue.append(request)
        
        if len(self.batch_queue) >= self.batch_size:
            await self.process_batch()
    
    async def process_batch(self):
        """
        Process batch using Claude Batch API (50% cost reduction)
        """
        if not self.batch_queue:
            return
        
        # Create batch request
        batch_id = await self.anthropic_service.create_batch_request(
            self.batch_queue
        )
        
        logger.info(f"Created batch {batch_id} with {len(self.batch_queue)} requests")
        
        # Clear queue
        self.batch_queue = []
        
        # Store batch ID for later retrieval
        await self.store_batch_id(batch_id)
    
    async def retrieve_batch_results(self, batch_id: str):
        """Retrieve and process batch results"""
        results = await self.anthropic_service.retrieve_batch_results(batch_id)
        
        # Process results
        for result in results:
            await self.process_result(result)
        
        return results
```

### 3. Caching Strategy

```python
import functools
from typing import Callable
import hashlib

class SmartCache:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def cache_llm_response(self, ttl: int = 86400):
        """
        Decorator to cache LLM responses
        TTL: 24 hours default
        """
        def decorator(func: Callable):
            @functools.wraps(func)
            async def wrapper(*args, **kwargs):
                # Create cache key from function name and arguments
                cache_key = self._create_cache_key(func.__name__, args, kwargs)
                
                # Check cache
                cached = self.redis.get(cache_key)
                if cached:
                    logger.info(f"Cache hit for {func.__name__}")
                    return json.loads(cached)
                
                # Call function
                result = await func(*args, **kwargs)
                
                # Cache result
                self.redis.setex(
                    cache_key,
                    ttl,
                    json.dumps(result)
                )
                
                return result
            
            return wrapper
        return decorator
    
    def _create_cache_key(self, func_name: str, args: tuple, 
                         kwargs: dict) -> str:
        """Create deterministic cache key"""
        key_data = {
            "function": func_name,
            "args": str(args),
            "kwargs": str(sorted(kwargs.items()))
        }
        
        key_str = json.dumps(key_data, sort_keys=True)
        hash_val = hashlib.md5(key_str.encode()).hexdigest()
        
        return f"llm_cache:{func_name}:{hash_val}"

# Usage
cache = SmartCache(redis_client)

@cache.cache_llm_response(ttl=86400)
async def generate_persona(cluster_data: dict) -> dict:
    """Cached persona generation"""
    return await anthropic_service.generate_persona(cluster_data)
```

### 4. Model Compression and Optimization

```python
# Quantization for local models
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

def quantize_model(model_name: str, output_path: str):
    """Quantize model to 8-bit for faster inference"""
    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        load_in_8bit=True,  # 8-bit quantization
        device_map="auto"
    )
    
    model.save_pretrained(output_path)
    
# ONNX export for faster inference
from optimum.onnxruntime import ORTModelForSequenceClassification

def export_to_onnx(model_name: str, output_path: str):
    """Export model to ONNX for optimized inference"""
    model = ORTModelForSequenceClassification.from_pretrained(
        model_name,
        export=True
    )
    
    model.save_pretrained(output_path)
```

---

## Fallback Mechanisms

```python
from typing import List, Callable, Any
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential
import logging

class ResilientMLService:
    def __init__(self):
        self.primary_services = {
            "embeddings": [
                self.openai_embeddings,
                self.local_embeddings
            ],
            "sentiment": [
                self.roberta_sentiment,
                self.vader_sentiment
            ],
            "ad_copy": [
                self.claude_generate,
                self.gpt4_generate,
                self.local_llm_generate,
                self.template_generate  # Final fallback
            ],
            "image": [
                self.dalle_generate,
                self.sdxl_generate,
                self.placeholder_image  # Final fallback
            ]
        }
    
    async def execute_with_fallback(self, service_type: str, 
                                   *args, **kwargs) -> Any:
        """
        Execute service with automatic fallback chain
        """
        services = self.primary_services.get(service_type, [])
        
        for i, service_func in enumerate(services):
            try:
                logger.info(f"Attempting {service_func.__name__}")
                result = await service_func(*args, **kwargs)
                
                # Log which service succeeded
                if i > 0:
                    logger.warning(f"Fallback to {service_func.__name__} succeeded")
                
                return {
                    "result": result,
                    "service_used": service_func.__name__,
                    "fallback_level": i
                }
                
            except Exception as e:
                logger.error(f"{service_func.__name__} failed: {e}")
                
                # If this was the last service, raise error
                if i == len(services) - 1:
                    raise Exception(f"All {service_type} services failed")
                
                # Otherwise, continue to next fallback
                continue
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def openai_embeddings(self, texts: List[str]) -> np.ndarray:
        """Primary: OpenAI embeddings"""
        service = OpenAIService()
        embeddings = await service.generate_embeddings(texts)
        return np.array(embeddings)
    
    async def local_embeddings(self, texts: List[str]) -> np.ndarray:
        """Fallback: Local sentence transformer"""
        model = SentenceTransformer('all-MiniLM-L6-v2')
        embeddings = model.encode(texts)
        return embeddings
    
    @retry(stop=stop_after_attempt(2))
    async def roberta_sentiment(self, text: str) -> dict:
        """Primary: RoBERTa sentiment"""
        # Implementation
        pass
    
    async def vader_sentiment(self, text: str) -> dict:
        """Fallback: VADER sentiment (always works, no API)"""
        from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        analyzer = SentimentIntensityAnalyzer()
        return analyzer.polarity_scores(text)
    
    @retry(stop=stop_after_attempt(2))
    async def claude_generate(self, prompt: str) -> str:
        """Primary: Claude"""
        service = AnthropicService()
        return await service.generate(prompt)
    
    @retry(stop=stop_after_attempt(2))
    async def gpt4_generate(self, prompt: str) -> str:
        """Fallback 1: GPT-4"""
        service = OpenAIService()
        return await service.generate(prompt)
    
    async def local_llm_generate(self, prompt: str) -> str:
        """Fallback 2: Local LLM (Llama)"""
        # vLLM or llama.cpp
        pass
    
    async def template_generate(self, prompt: str) -> str:
        """Fallback 3: Template-based generation (always works)"""
        # Extract key information and use templates
        return self.generate_from_template(prompt)
    
    async def dalle_generate(self, prompt: str) -> str:
        """Primary: DALL-E 3"""
        service = OpenAIService()
        return await service.generate_image(prompt)
    
    async def sdxl_generate(self, prompt: str) -> str:
        """Fallback 1: Stable Diffusion XL (local)"""
        # Local SDXL generation
        pass
    
    async def placeholder_image(self, prompt: str) -> str:
        """Fallback 2: Generate placeholder image"""
        # Return URL to placeholder service
        return f"https://via.placeholder.com/1024x1024?text={prompt[:50]}"

# Circuit breaker pattern
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    async def call(self, func: Callable, *args, **kwargs):
        """Call function with circuit breaker"""
        
        # If circuit is OPEN, check if timeout has passed
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            
            # Reset on success
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            
            return result
            
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            # Open circuit if threshold reached
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
                logger.error(f"Circuit breaker opened after {self.failure_count} failures")
            
            raise e

# Usage
resilient_service = ResilientMLService()

# Generate embeddings with automatic fallback
result = await resilient_service.execute_with_fallback(
    "embeddings",
    ["text1", "text2", "text3"]
)

print(f"Used service: {result['service_used']}")
print(f"Fallback level: {result['fallback_level']}")
print(f"Result: {result['result']}")
```

---

## Quality Assurance and Content Moderation

### 1. Content Moderation Pipeline

```python
from typing import Dict, List
import re

class ContentModerator:
    def __init__(self):
        self.openai_service = OpenAIService()
        self.perspective_api = PerspectiveAPI()
        
    async def moderate_ad_content(self, ad: dict) -> dict:
        """
        Comprehensive ad content moderation
        """
        moderation_results = {
            "approved": True,
            "flags": [],
            "scores": {}
        }
        
        # 1. OpenAI Moderation API
        openai_mod = await self.openai_moderation(ad['text'])
        if openai_mod['flagged']:
            moderation_results['approved'] = False
            moderation_results['flags'].append("openai_moderation")
        moderation_results['scores']['openai'] = openai_mod
        
        # 2. Perspective API (toxicity, profanity, etc.)
        perspective_scores = await self.perspective_api.analyze(ad['text'])
        if any(score > 0.7 for score in perspective_scores.values()):
            moderation_results['approved'] = False
            moderation_results['flags'].append("perspective_toxicity")
        moderation_results['scores']['perspective'] = perspective_scores
        
        # 3. Custom brand safety checks
        brand_safe = self.check_brand_safety(ad['text'])
        if not brand_safe['safe']:
            moderation_results['approved'] = False
            moderation_results['flags'].extend(brand_safe['violations'])
        
        # 4. Compliance checks (legal, regulatory)
        compliance = self.check_compliance(ad)
        if not compliance['compliant']:
            moderation_results['approved'] = False
            moderation_results['flags'].extend(compliance['violations'])
        
        # 5. Image moderation (if image included)
        if 'image_url' in ad:
            image_mod = await self.moderate_image(ad['image_url'])
            if not image_mod['approved']:
                moderation_results['approved'] = False
                moderation_results['flags'].append("image_violation")
        
        return moderation_results
    
    async def openai_moderation(self, text: str) -> dict:
        """OpenAI Moderation API"""
        response = await self.openai_service.client.moderations.create(
            input=text
        )
        return response.results[0].model_dump()
    
    def check_brand_safety(self, text: str) -> dict:
        """Custom brand safety rules"""
        violations = []
        
        # Blocked keywords
        blocked_keywords = [
            "guaranteed", "risk-free", "100% effective",
            "miracle", "cure-all", "secret", "limited time only"
        ]
        
        text_lower = text.lower()
        for keyword in blocked_keywords:
            if keyword in text_lower:
                violations.append(f"blocked_keyword:{keyword}")
        
        # ALL CAPS check
        if text.isupper() and len(text) > 10:
            violations.append("excessive_caps")
        
        # Excessive punctuation
        if text.count('!') > 2 or text.count('?') > 2:
            violations.append("excessive_punctuation")
        
        return {
            "safe": len(violations) == 0,
            "violations": violations
        }
    
    def check_compliance(self, ad: dict) -> dict:
        """Check regulatory compliance"""
        violations = []
        
        # Require disclaimers for certain claims
        if any(claim in ad['text'].lower() for claim in ['guarantee', 'proven', 'clinically tested']):
            if 'disclaimer' not in ad or not ad['disclaimer']:
                violations.append("missing_disclaimer")
        
        # Age-restricted content checks
        if ad.get('product_category') in ['alcohol', 'tobacco', 'gambling']:
            if not ad.get('age_targeting') or ad['age_targeting']['min_age'] < 21:
                violations.append("age_restriction_violation")
        
        # Privacy compliance (GDPR, CCPA)
        if 'data_collection' in ad['text'].lower():
            if 'privacy_policy_link' not in ad:
                violations.append("privacy_policy_required")
        
        return {
            "compliant": len(violations) == 0,
            "violations": violations
        }
    
    async def moderate_image(self, image_url: str) -> dict:
        """Moderate image content"""
        # Use OpenAI Vision API or similar
        response = await self.openai_service.client.chat.completions.create(
            model="gpt-4o",
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": "Does this image contain any inappropriate, offensive, or unsafe content? Answer with JSON: {\"approved\": true/false, \"reason\": \"explanation\"}"},
                    {"type": "image_url", "image_url": {"url": image_url}}
                ]
            }],
            response_format={"type": "json_object"}
        )
        
        result = json.loads(response.choices[0].message.content)
        return result

class PerspectiveAPI:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.url = "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze"
    
    async def analyze(self, text: str) -> dict:
        """Analyze text toxicity using Perspective API"""
        import aiohttp
        
        payload = {
            "comment": {"text": text},
            "requestedAttributes": {
                "TOXICITY": {},
                "SEVERE_TOXICITY": {},
                "IDENTITY_ATTACK": {},
                "INSULT": {},
                "PROFANITY": {},
                "THREAT": {}
            }
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.url}?key={self.api_key}",
                json=payload
            ) as response:
                result = await response.json()
        
        scores = {
            attr: result['attributeScores'][attr]['summaryScore']['value']
            for attr in payload['requestedAttributes'].keys()
        }
        
        return scores
```

### 2. Quality Scoring

```python
class AdQualityScorer:
    def __init__(self):
        self.openai_service = OpenAIService()
    
    async def score_ad_quality(self, ad: dict, persona: dict) -> dict:
        """
        Score ad quality across multiple dimensions
        """
        scores = {}
        
        # 1. Relevance to persona
        scores['relevance'] = await self.score_relevance(ad, persona)
        
        # 2. Creativity and engagement
        scores['creativity'] = await self.score_creativity(ad)
        
        # 3. Clarity and readability
        scores['clarity'] = self.score_clarity(ad['text'])
        
        # 4. CTA effectiveness
        scores['cta_effectiveness'] = self.score_cta(ad)
        
        # 5. Brand alignment
        scores['brand_alignment'] = await self.score_brand_alignment(ad)
        
        # Overall score (weighted average)
        weights = {
            'relevance': 0.3,
            'creativity': 0.2,
            'clarity': 0.2,
            'cta_effectiveness': 0.15,
            'brand_alignment': 0.15
        }
        
        overall_score = sum(
            scores[key] * weights[key]
            for key in weights.keys()
        )
        
        return {
            "overall_score": overall_score,
            "dimension_scores": scores,
            "recommendation": self.get_recommendation(overall_score)
        }
    
    async def score_relevance(self, ad: dict, persona: dict) -> float:
        """Score relevance using embeddings similarity"""
        model = SentenceTransformer('all-MiniLM-L6-v2')
        
        ad_embedding = model.encode(ad['text'])
        persona_embedding = model.encode(
            f"{persona['interests']} {persona['pain_points']}"
        )
        
        from sklearn.metrics.pairwise import cosine_similarity
        similarity = cosine_similarity(
            [ad_embedding],
            [persona_embedding]
        )[0][0]
        
        return float(similarity)
    
    async def score_creativity(self, ad: dict) -> float:
        """Score creativity using LLM"""
        prompt = f"""Rate the creativity and engagement potential of this ad copy on a scale of 0-1:

Ad: {ad['text']}

Consider:
- Originality
- Emotional appeal
- Memorability
- Use of storytelling

Return only a number between 0 and 1."""

        response = await self.openai_service.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        
        score = float(response.choices[0].message.content.strip())
        return max(0.0, min(1.0, score))
    
    def score_clarity(self, text: str) -> float:
        """Score clarity using readability metrics"""
        import textstat
        
        # Flesch Reading Ease (0-100, higher is easier)
        flesch = textstat.flesch_reading_ease(text)
        
        # Normalize to 0-1
        normalized_score = flesch / 100
        
        # Penalize if too complex or too simple
        if flesch < 30 or flesch > 90:
            normalized_score *= 0.7
        
        return max(0.0, min(1.0, normalized_score))
    
    def score_cta(self, ad: dict) -> float:
        """Score CTA effectiveness"""
        cta = ad.get('cta', '').lower()
        
        # Strong CTAs
        strong_ctas = [
            'shop now', 'buy now', 'get started', 'try free',
            'claim offer', 'limited time', 'join now', 'download'
        ]
        
        # Weak CTAs
        weak_ctas = ['click here', 'learn more', 'read more']
        
        score = 0.5  # Default
        
        if any(strong in cta for strong in strong_ctas):
            score = 0.9
        elif any(weak in cta for weak in weak_ctas):
            score = 0.6
        
        # Bonus for urgency
        if any(urgent in cta for urgent in ['now', 'today', 'limited']):
            score = min(1.0, score + 0.1)
        
        return score
    
    async def score_brand_alignment(self, ad: dict) -> float:
        """Score brand voice alignment"""
        # Load brand guidelines
        brand_voice = load_brand_guidelines()
        
        # Use LLM to assess alignment
        prompt = f"""Rate how well this ad aligns with our brand voice (0-1):

Brand Voice: {brand_voice}
Ad: {ad['text']}

Return only a number between 0 and 1."""

        response = await self.openai_service.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        
        score = float(response.choices[0].message.content.strip())
        return max(0.0, min(1.0, score))
    
    def get_recommendation(self, score: float) -> str:
        """Get recommendation based on score"""
        if score >= 0.8:
            return "APPROVED - High quality, ready to deploy"
        elif score >= 0.6:
            return "APPROVED_WITH_REVIEW - Good quality, minor improvements suggested"
        elif score >= 0.4:
            return "NEEDS_IMPROVEMENT - Significant revisions recommended"
        else:
            return "REJECTED - Quality too low, regenerate"
```

### 3. Automated Testing

```python
import pytest
from typing import List

class AdQualityTests:
    """Automated tests for ad quality"""
    
    @pytest.fixture
    def sample_ad(self):
        return {
            "headline": "Transform Your Business Today",
            "body": "Discover powerful tools that help you grow faster",
            "cta": "Start Free Trial",
            "text": "Transform Your Business Today. Discover powerful tools that help you grow faster. Start Free Trial"
        }
    
    def test_length_constraints(self, ad: dict):
        """Test ad length constraints"""
        assert len(ad['headline']) <= 100, "Headline too long"
        assert len(ad['body']) <= 200, "Body too long"
        assert len(ad['cta']) <= 30, "CTA too long"
    
    def test_has_cta(self, ad: dict):
        """Test that ad has a CTA"""
        assert 'cta' in ad and len(ad['cta']) > 0, "Missing CTA"
    
    def test_no_spam_words(self, ad: dict):
        """Test for spam trigger words"""
        spam_words = ['free money', 'click here', 'act now', 'limited time offer']
        text_lower = ad['text'].lower()
        
        for spam_word in spam_words:
            assert spam_word not in text_lower, f"Contains spam word: {spam_word}"
    
    def test_sentiment_positive(self, ad: dict):
        """Test that ad sentiment is positive"""
        from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        
        analyzer = SentimentIntensityAnalyzer()
        sentiment = analyzer.polarity_scores(ad['text'])
        
        assert sentiment['compound'] > 0, "Ad sentiment should be positive"
    
    def test_readability(self, ad: dict):
        """Test readability score"""
        import textstat
        
        score = textstat.flesch_reading_ease(ad['text'])
        assert score >= 40, "Ad is too difficult to read"
    
    async def test_moderation_pass(self, ad: dict):
        """Test that ad passes moderation"""
        moderator = ContentModerator()
        result = await moderator.moderate_ad_content(ad)
        
        assert result['approved'], f"Moderation failed: {result['flags']}"
    
    async def test_quality_threshold(self, ad: dict, persona: dict):
        """Test that ad meets quality threshold"""
        scorer = AdQualityScorer()
        result = await scorer.score_ad_quality(ad, persona)
        
        assert result['overall_score'] >= 0.6, "Ad quality below threshold"

# Run tests in CI/CD
def run_ad_tests(ads: List[dict], personas: List[dict]):
    """Run all quality tests on generated ads"""
    tester = AdQualityTests()
    
    results = []
    for ad, persona in zip(ads, personas):
        test_results = {
            "ad_id": ad['id'],
            "tests_passed": 0,
            "tests_failed": 0,
            "failures": []
        }
        
        # Run each test
        tests = [
            ('length_constraints', lambda: tester.test_length_constraints(ad)),
            ('has_cta', lambda: tester.test_has_cta(ad)),
            ('no_spam', lambda: tester.test_no_spam_words(ad)),
            ('sentiment', lambda: tester.test_sentiment_positive(ad)),
            ('readability', lambda: tester.test_readability(ad)),
        ]
        
        for test_name, test_func in tests:
            try:
                test_func()
                test_results['tests_passed'] += 1
            except AssertionError as e:
                test_results['tests_failed'] += 1
                test_results['failures'].append({
                    "test": test_name,
                    "error": str(e)
                })
        
        results.append(test_results)
    
    return results
```

---

## Technology Stack

### Complete Stack Summary

```yaml
# Data Infrastructure
data_warehouse: BigQuery / Snowflake
data_lake: AWS S3 / Google Cloud Storage
feature_store: Feast / Tecton
streaming: Apache Kafka + Flink

# ML Infrastructure
training:
  - Google Vertex AI / AWS SageMaker
  - PyTorch / TensorFlow
  - Weights & Biases (experiment tracking)
  
serving:
  - Ray Serve (primary)
  - Triton Inference Server (high throughput)
  - vLLM (LLM serving)
  
model_registry: MLflow

# APIs & Models
llm_apis:
  - Anthropic Claude (persona, ad copy)
  - OpenAI GPT-4o (embeddings, ad copy)
  - OpenAI DALL-E 3 (image generation)
  
local_models:
  - sentence-transformers/all-MiniLM-L6-v2 (embeddings)
  - meta-llama/Meta-Llama-3.1-70B-Instruct (ad copy)
  - stabilityai/stable-diffusion-xl-base-1.0 (images)
  - cardiffnlp/twitter-roberta-base-sentiment-latest (sentiment)

# NLP & ML Libraries
nlp:
  - spaCy (NER, parsing)
  - NLTK (text preprocessing)
  - transformers (HuggingFace)
  - bertopic (topic modeling)
  
ml:
  - scikit-learn (clustering, classification)
  - hdbscan (clustering)
  - umap-learn (dimensionality reduction)
  - lightgbm (ranking)
  
# Vector Databases
vector_db:
  primary: Pinecone (managed)
  alternative: Qdrant (self-hosted)
  development: ChromaDB
  
# Caching & Queue
cache: Redis (caching, rate limiting)
queue: Celery + RabbitMQ (async tasks)

# Orchestration
workflow: Apache Airflow
deployment: Kubernetes
monitoring: Prometheus + Grafana
logging: ELK Stack (Elasticsearch, Logstash, Kibana)

# API Framework
api: FastAPI
authentication: JWT
rate_limiting: Redis

# Frontend (optional)
dashboard: Streamlit / Gradio

# DevOps
ci_cd: GitHub Actions / GitLab CI
containerization: Docker
infrastructure: Terraform
secrets: HashiCorp Vault

# Monitoring & Observability
apm: DataDog / New Relic
error_tracking: Sentry
analytics: Mixpanel / Amplitude
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] Set up data ingestion pipeline
- [ ] Implement data preprocessing
- [ ] Deploy embedding generation (batch)
- [ ] Set up vector database (Pinecone)
- [ ] Implement sentiment analysis
- [ ] Deploy basic API (FastAPI)

### Phase 2: ML Core (Weeks 5-8)
- [ ] Implement clustering pipeline
- [ ] Build persona generation system
- [ ] Integrate Claude/GPT-4 for ad copy
- [ ] Set up feature store
- [ ] Implement caching layer
- [ ] Deploy ML model serving (Ray Serve)

### Phase 3: Advanced Features (Weeks 9-12)
- [ ] Add image generation (DALL-E/SDXL)
- [ ] Implement A/B testing framework
- [ ] Build recommendation system
- [ ] Set up model versioning (MLflow)
- [ ] Implement content moderation
- [ ] Deploy quality scoring

### Phase 4: Production & Optimization (Weeks 13-16)
- [ ] Implement cost optimization
- [ ] Add fallback mechanisms
- [ ] Set up monitoring & alerting
- [ ] Performance optimization
- [ ] Load testing
- [ ] Documentation

### Phase 5: Scale & Iterate (Ongoing)
- [ ] Auto-scaling infrastructure
- [ ] Continuous model improvement
- [ ] A/B test new models
- [ ] Expand to new platforms
- [ ] Advanced personalization

---

## Estimated Costs

### Monthly Operating Costs (10,000 users)

```
Infrastructure:
- Cloud compute (GPUs): $3,000 - $5,000
- Storage (S3/GCS): $500
- Kubernetes cluster: $1,000
- Vector DB (Pinecone): $700

APIs:
- OpenAI (embeddings, GPT-4o): $2,000 - $4,000
- Anthropic (Claude): $1,500 - $3,000
- Image generation: $1,000 - $2,000

Total: $9,700 - $16,200/month
```

### Cost per User
- Approximately $1 - $1.60 per user per month
- Can be reduced to $0.50 - $0.80 with optimization

---

This design provides a production-ready, scalable AI/ML pipeline for follower analysis and ad generation. The architecture supports both batch and real-time processing, includes comprehensive fallback mechanisms, and implements industry best practices for cost optimization and quality assurance.
