# NorthPeak Bank AI support assistant: BA case study

A business-analysis case study of rolling out an AI support agent at a (fictional) digital bank:
which customer queries to automate, where the AI must hand off to a human, and how to test it before go-live.

**NorthPeak Bank is fictional.** All policies, fees and limits in `knowledge_base.md` are invented for this demo.

## What's in here

| File | What it is |
|---|---|
| `knowledge_base.md` | The bot's only source of truth: 11 policy sections, each with an ID and effective date, plus one deliberately superseded fee document to test source freshness. |
| `bot.py` | The assistant. Sends the knowledge base + rules to Llama 3.3 70B on Groq and returns structured JSON (answer, sources, escalate, reason). Falls back to a human handoff if the output is invalid. |
| `app.py` | Streamlit chat UI showing the answer, cited sources and any handoff. |
| `test_cases.csv` | 45 UAT scenarios across 9 risk categories: in-scope answers, source freshness, out-of-scope questions, account-specific triage, high-risk handoffs, prompt injection, data leakage, Hinglish and explicit escalation requests. |
| `run_uat.py` | Runs every test case through the bot, applies automatic checks and writes `uat_results_<version>.csv`. |
| `support_analysis.sql` | MySQL analysis of 10,003 customer queries (Banking77) used to decide what to automate. |

## Run it

```
pip install -r requirements.txt
```

Set your Groq API key (Windows PowerShell):
```
$env:GROQ_API_KEY="your-key-here"
```

Chat with the bot:
```
streamlit run app.py
```

Run the UAT suite:
```
python run_uat.py v1
```

## Data

Query analysis uses the Banking77 dataset (PolyAI, CC BY 4.0): https://github.com/PolyAI-LDN/task-specific-datasets
